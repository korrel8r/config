# Generate sample signal data as a sequence of JSON objects

help:
	@echo
	@echo "Generate sample values for observability signals from current cluster."
	@echo "You need to be logged in as an admin user with a token (e.g. kube:admin)."
	@echo "Query results are 'unwrapped' so that each signal is presented consistently"
	@echo "as a sequence (not array) of pretty-printed JSON objects, one per signal instance"
	@echo
	@echo "make <signal-type>: generate data for that type to stdout or $OUTDIR"
	@echo "Signal types:" $(SIGNALS)
	@echo "Variables: LIMIT (limit number of results)"
	@echo
	@grep '^[^ ]*: ##' $(MAKEFILE_LIST)

SIGNALS=$(shell grep '^[^ ]*: ### ' $(MAKEFILE_LIST) | sed 's/: ###.*//')
SIGNAL_FILES=$(addprefix $(SAMPLE_DIR)/,$(addsuffix .json,$(SIGNALS))
# Limit number of values
LIMIT?=100

CURL=curl -sS -k -H "Authorization: Bearer $(shell oc whoami -t)"
JQ=jq -M
REDIRECT=$(and $(OUTDIR),> $(OUTDIR)/$@.json)

.PHONY: $(SIGNALS) help examples update

clean: ## Remove all samples
	rm $(SAMPLE_DIR)/*

update: ## Update all files in ./samples from cluster.
	for S in $(SIGNALS); do echo; echo "### $$S";  $(MAKE) --no-print-directory OUTDIR=samples $$S; done

LOKISTACK_HOST=$(shell oc get -n openshift-logging route/logging-loki -o jsonpath='{.status.ingress[0].host}' )
LOKISTACK_API=https://$(LOKISTACK_HOST)/api/logs/v1/$(1)/loki/api/v1
CURL_LOGS=$(CURL) --get --data-urlencode 'query={log_type=~".+"}' --data-urlencode 'limit=$(LIMIT)' \
	$(call LOKISTACK_API,$(1))/query_range  | $(JQ) '.data.result[].values[][1] | fromjson'  $(REDIRECT)

logs-application: ### Application logs from default cluster LokiStack.
	$(call CURL_LOGS,application)
logs-infrastructure: ### Infrastructure logs from default cluster LokiStack.
	$(call CURL_LOGS,infrastructure)
logs-audit: ### Audit logs from default cluster LokiStack.
	$(call CURL_LOGS,audit)

events: ### Kubernetes events.
	oc get events -A -o json | $(JQ) .items[]  $(REDIRECT)

THANOS_HOST=$(shell oc get route thanos-querier -n openshift-monitoring -o json | $(JQ) -r '.spec.host')

metrics: ### Metrics from Thanos
	$(CURL) --get --data-urlencode 'query=topk($(LIMIT), {__name__=~".+"})' --data-urlencode 'limit=$(LIMIT)' "https://$(THANOS_HOST)/api/v1/query" | $(JQ) .data.result[]  $(REDIRECT)

thanos-rules: ### Alerting rules from Thanos
	$(CURL) --get --data-urlencode 'type=alert' "https://$(THANOS_HOST)/api/v1/rules" | $(JQ) .data.groups[].rules[] $(REDIRECT)

cluster-rules: ### Cluster alerting rule objects from API server.
	oc get prometheusrule -A -o json | $(JQ) .items[].spec.groups[].rules[]  $(REDIRECT)

ALERTMANAGER_HOST=$(shell oc get route alertmanager-main -n openshift-monitoring -o jsonpath='{@.spec.host}')

alerts: ### Alerts from cluster alertmanager
	$(CURL) https://$(ALERTMANAGER_HOST)/api/v1/alerts | $(JQ) '.data[]' $(REDIRECT)

traces: ### Traces from Jaeger (WIP)
	$(CURL) https://jaeger-all-in-one-inmemory-tracing-system.apps.snoflake.my.test/api/traces?service=jaeger-query | $(JQ) '.data[]'  $(REDIRECT)


test-log-generator: ## Generates application logs.
	oc create namespace $@ || true
	oc run $@ -n $@ --image quay.io/rojacob/cluster-logging-load-client:0.0.1-db25b80

clean-cluster:
	oc delete ns/test-log-generator

API_NS=openshift-kube-apiserver
API_POD=$(shell oc get pod -n $(API_NS) -l apiserver=true -o name | head -n1)
api-audit: ## API server audit logs directly from API kube-apiserver
	oc exec -n $(API_NS) $(API_POD) -- sh -c 'cat /var/log/kube-apiserver/audit.log | tail -n $(LIMIT)' $(REDIRECT)
