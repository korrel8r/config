# Deploy operators and resources for observability components.
#
# NOTE: each component can be installed with just `kubectl apply -f <directory>/`
#
# This Makefile also ensure dependencies are respected, and waits till components are ready, reporting errors.
# It also provides all: and backends: targets to install everyhing on a new cluster.
#

ALL=$(BACKENDS) uiplugins route
BACKENDS=minio lokistack logging netobserv tempo
OPERATORS?=true

all: $(ALL)

backends: $(BACKENDS)

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

.PHONY: minio
minio:
	kubectl apply -f $@/
	./wait.sh rollout minio deployment/minio

.PHONY: lokistack
lokistack: minio
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
tempo:
	kubectl apply -f $@/00_projects.yaml -f $@/10_operators.yaml
	./wait.sh subscription openshift-tempo-operator tempo-product
	./wait.sh subscription openshift-opentelemetry-operator opentelemetry-product
	./wait.sh crd tempostacks.tempo.grafana.com
	kubectl apply -f $@/
	./wait.sh rollout openshift-tracing deployment.apps/tempo-platform-gateway

clean-cluster:
	$(foreach X,$(ALL),kubectl delete --ignore-not-found -f $(X)/ & ) wait
