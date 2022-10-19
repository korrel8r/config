# NOTE: using single process Loki with vector forwarder.
# NOT using LokiStack, but the JSON format of the resulting logs is the same.

PATH:=$(PATH):$(CURDIR)/bin

all: deploy logs

HOST=$(shell oc get -n openshift-logging route/loki -o jsonpath='{.status.ingress[0].host}{"\n"}')

deploy:
	oc create ns openshift-logging || true
	oc apply -f loki.yaml -f ../chat.yaml
	oc wait --for=condition=ready -n openshift-logging pod/loki

logging:
	oc apply -f logging.yaml
	oc wait --for=condition=ready -n openshift-logging clf/instance

undeploy:
	oc delete --ignore-not-found -f loki.yaml logging.yaml

logs:
	until logcli -o raw --quiet --addr=http://$(HOST) query '{log_type=~".+"}' | grep log_type; do sleep 3; done

host:
	@echo $(HOST)
