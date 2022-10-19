# Generate sample signal data as a sequence of JSON objects

help:
	@echo
	@echo "Generate sample values for observability signals from a cluster."
	@echo "Signal types are: $(SIGNALS)"
	@echo "Query results are 'unwrapped' so that each signal is presented consistently"
	@echo "as a sequence (not array) of pretty-printed JSON objects, one per signal instance"
	@echo
	@echo "make <signal-type>: generate data for that type to stdout"
	@echo "make update: generate data for all types, update files <signal-type>.json"
	@echo "make examples: print the first value from each .json file as an example"

SIGNALS=alerts logs events metrics traces
SIGNAL_FILES=$(addsuffix .json,$(SIGNALS))

CURL=curl -sS --fail-with-body -k -H "Authorization: Bearer $(shell oc whoami -t)"
JQ=jq -M

.PHONY: $(SIGNALS) help


alerts:
	HOST=$$(oc get route alertmanager-main -n openshift-monitoring -o jsonpath='{@.spec.host}'); \
	$(CURL) https://$$HOST/api/v1/alerts | $(JQ) '.data[]'

logs:
	HOST=$$(oc get -n openshift-logging route/loki -o jsonpath='{.status.ingress[0].host}'); \
	$(CURL) --get --data-urlencode 'query={log_type="application"}' --data-urlencode 'limit=100' http://$$HOST/loki/api/v1/query_range | $(JQ) '.data.result[].values[][1] | fromjson'

events:
	oc get events -A -o json | $(JQ) .items[]

METRICS_HOST=$(shell oc get route thanos-querier -n openshift-monitoring -o json | $(JQ) -r '.spec.host')
metrics: # Take the 100 biggest values, getting all metrics is a lot of data.
	$(CURL) --get --data-urlencode 'query=topk(100, {__name__=~".+"})' --data-urlencode 'limit=100' "https://$(METRICS_HOST)/api/v1/query" | $(JQ) .data.result[]

traces:
	$(CURL) https://jaeger-all-in-one-inmemory-tracing-system.apps.snoflake.my.test/api/traces?service=jaeger-query | $(JQ) '.data[]'

update:
	for S in $(SIGNALS); do echo "# $$S"; $(MAKE) -s $$S > $$S.json; done

examples:
	for S in $(SIGNALS); do echo; echo "## $$S"; cat $$S.json | $(JQ) -s '. | first'; done

alerting-rules.yaml:
	oc get prometheusrule -A -o yaml > alerting-rules.yaml
