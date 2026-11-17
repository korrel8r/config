#!/usr/bin/env bash

set -e -o pipefail

# Each resource gets one deadline, shared by creation and readiness checks.
declare -r WAIT_TIMEOUT=${WAIT_TIMEOUT:-60}  # Seconds.
declare -r POLL_INTERVAL=${POLL_INTERVAL:-1}

remaining() {
	local -i seconds=$(( $1 - SECONDS ))
	(( seconds > 0 )) || return 1
	printf '%s' "$seconds"
}

# Poll for existence or a nonempty field; watch readiness rather than polling it.
wait_for_resource() {
	local deadline=$1
	shift
	echo "Waiting for: $*"
	while ! "$@"; do
		remaining "$deadline" >/dev/null || {
			echo "Timed out waiting for: $*" >&2
			return 1
		}
		sleep "$POLL_INTERVAL"
	done
}

resource_exists() { "$@" >/dev/null 2>&1; }
has_value() { [[ -n $("$@" 2>/dev/null) ]]; }

# kubectl wait for Succeeded cannot detect a CSV that has already Failed.
wait_for_csv() {
	local ns=$1 csv=$2 deadline=$3 phase
	echo "Waiting for CSV $ns/$csv to succeed"
	while :; do
		phase=$(kubectl -n "$ns" get "csv/$csv" -o jsonpath='{.status.phase}') || return 1
		case "$phase" in
			Succeeded) return 0 ;;
			Failed)
				echo "CSV $ns/$csv failed:" >&2
				kubectl -n "$ns" get "csv/$csv" -o jsonpath='{.status.reason}{": "}{.status.message}{"\n"}' >&2
				return 1 ;;
		esac
		remaining "$deadline" >/dev/null || {
			echo "Timed out waiting for CSV $ns/$csv (phase: $phase)" >&2
			return 1
		}
		sleep "$POLL_INTERVAL"
	done
}

subscription() {
	local ns=$1 name csv deadline
	shift
	for name in "$@"; do
		deadline=$((SECONDS + WAIT_TIMEOUT))
		wait_for_resource "$deadline" resource_exists kubectl -n "$ns" get "subscription/$name" || return 1
		kubectl -n "$ns" wait --for=jsonpath='{.status.state}'=AtLatestKnown \
			"subscription/$name" --timeout="$(remaining "$deadline")s" || return 1
		wait_for_resource "$deadline" has_value kubectl -n "$ns" get "subscription/$name" -o jsonpath='{.status.currentCSV}' || return 1
		csv=$(kubectl -n "$ns" get "subscription/$name" -o jsonpath='{.status.currentCSV}')
		wait_for_resource "$deadline" resource_exists kubectl -n "$ns" get "csv/$csv" || return 1
		wait_for_csv "$ns" "$csv" "$deadline" || return 1
	done
}

crd() {
	local name deadline
	for name in "$@"; do
		deadline=$((SECONDS + WAIT_TIMEOUT))
		wait_for_resource "$deadline" resource_exists kubectl get "crd/$name" || return 1
		kubectl wait --for=condition=established "crd/$name" --timeout="$(remaining "$deadline")s" || return 1
	done
}

# Wait for creation, then watch rollout status once with the remaining time.
rollout() {
	local ns=$1 deadline
	shift
	deadline=$((SECONDS + WAIT_TIMEOUT))
	wait_for_resource "$deadline" resource_exists kubectl -n "$ns" get "$@" || return 1
	kubectl -n "$ns" rollout status --watch --timeout="$(remaining "$deadline")s" "$@"
}

show_usage() {
	echo "Usage: $0 {subscription|rollout} NAMESPACE RESOURCE... | crd RESOURCE..."
}

main() {
	(( $# >= 1 )) || { show_usage; return 1; }
	local op=$1
	shift
	case "$op" in
		subscription | rollout)
			(( $# >= 2 )) || { show_usage; return 1; }
			kubectl get events -n "$1" --watch-only &
			event_pid=$!
			trap 'kill "$event_pid" 2>/dev/null || true' EXIT
			"$op" "$@"
			;;
		crd)
			(( $# >= 1 )) || { show_usage; return 1; }
			crd "$@"
			;;
		*) show_usage; return 1 ;;
	esac
}

echo "$0 $*"
main "$@"
