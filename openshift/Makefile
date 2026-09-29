# Deploy operators and resources for observability components.
#
# NOTE: each component can be installed with just `kubectl apply -f <directory>/`
#
# This Makefile also ensure dependencies are respected, and waits till components are ready, reporting errors.
# It also provides all: and backends: targets to install everyhing on a new cluster.
#

OPERATORS?=true
COO_NAMESPACE?=openshift-cluster-observability-operator

signals: namespace seaweedfs lokistack logging netobserv tempo
after-coo: route uiplugins
all: signals coo after-coo
namespace:
	oc create ns $(COO_NAMESPACE) || true

# Find default storage class.
DEFAULT_SC=$(shell kubectl get storageclass -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
STORAGE_CLASS?=$(or $(strip $(DEFAULT_SC)),$(error Cannot determine storage class, must set STORAGE_CLASS.))
STORAGE_SED=sed -i 's/storageClassName:.*/storageClassName: $(STORAGE_CLASS)/'

.PHONY: route
route:
	kubectl apply -f $@/

.PHONY: uiplugins
uiplugins:
	kubectl apply -f $@/

.PHONY: seaweedfs
seaweedfs:
	kubectl apply -f $@/
	./wait.sh rollout seaweedfs deployment/seaweedfs

.PHONY: lokistack
lokistack: seaweedfs
	if $(OPERATORS); then \
		 kubectl apply -f $@/*-operator.yaml && \
		./wait.sh subscription openshift-operators-redhat loki-operator && \
		./wait.sh crd alertingrules.loki.grafana.com lokistacks.loki.grafana.com recordingrules.loki.grafana.com rulerconfigs.loki.grafana.com; \
	fi
	kubectl apply -f $@

.PHONY: logging
LOG_FORMAT?=viaq
logging:
	$(STORAGE_SED) $@/lokistack.yaml
	if $(OPERATORS); then \
		kubectl apply -f $@/*-operator.yaml && \
		./wait.sh subscription openshift-logging cluster-logging && \
./wait.sh crd clusterlogforwarders.observability.openshift.io; \
	fi
	kubectl apply -f $@ -f $@/$(LOG_FORMAT)
	./wait.sh rollout openshift-logging deployment.apps/cluster-logging-operator

.PHONY: netobserv
netobserv: lokistack
	$(STORAGE_SED) $@/lokistack.yaml
	kubectl apply -f $@/*-operator.yaml
	./wait.sh subscription openshift-netobserv-operator netobserv-operator
	./wait.sh crd flowcollectors.flows.netobserv.io flowmetrics.flows.netobserv.io
	kubectl apply -f $@/
	./wait.sh rollout openshift-netobserv-operator deployment.apps/netobserv-controller-manager

.PHONY: tempo
tempo: seaweedfs
	kubectl apply -f $@/00_projects.yaml -f $@/10_operators.yaml
	./wait.sh subscription openshift-tempo-operator tempo-product
	./wait.sh subscription openshift-opentelemetry-operator opentelemetry-product
	./wait.sh crd tempostacks.tempo.grafana.com
	kubectl apply -f $@/
	./wait.sh rollout openshift-tracing deployment.apps/tempo-platform-gateway

.PHONY: coo
coo:
	kubectl apply -f $@/
	./wait.sh subscription openshift-cluster-observability-operator cluster-observability-operator
	./wait.sh crd uiplugins.observability.openshift.io
	$(MAKE) route

.PHONY: telemetrygen
telemetrygen:
	kubectl delete -f $@/ || true
	kubectl apply -f $@/

delete:
	kubectl delete --ignore-not-found -f $(or $(DELETE),$(error Must set DELETE))/ || true

delete-all:
	$(foreach DIR,$(shell find * -type d -prune | grep -v seaweedfs),$(MAKE) delete DELETE=$(DIR) &) wait

clean-cluster: delete-all


.PHONY: lightspeed
lightspeed:
	$(MAKE) -C $@ all
