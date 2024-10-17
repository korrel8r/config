# Deploy operators and resources for observability components.
#
# NOTE: each component can be installed with just `kubectl apply -f <directory>/`
#
# This Makefile also ensure dependencies are respected, and waits till components are ready, reporting errors.
# It also provides all: and backends: targets to install everyhing on a new cluster.
#

ALL=uiplugins $(BACKENDS) 
BACKENDS=minio lokistack logging netobserv tempo 

all: $(ALL)

backends: $(BACKENDS)

# Find default storage class.
DEFAULT_SC=$(shell kubectl get storageclass -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
STORAGE_CLASS?=$(or $(strip $(DEFAULT_SC)),$(error Cannot determine storage class, must set STORAGE_CLASS.))
STORAGE_SED=sed -i 's/storageClassName:.*/storageClassName: $(STORAGE_CLASS)/'

.PHONY: uiplugins
uiplugins:
	kubectl apply -f $@/

.PHONY: minio
minio:
	kubectl apply -f $@/
	./wait.sh rollout minio deployment/minio

.PHONY: lokistack
lokistack: minio
	kubectl apply -f $@/
	./wait.sh subscription openshift-operators-redhat loki-operator

.PHONY: logging
logging: lokistack
	$(STORAGE_SED) $@/lokistack.yaml
	kubectl apply -f $@
	./wait.sh subscription openshift-logging cluster-logging
	./wait.sh rollout openshift-logging deployment.apps/logging-loki-gateway
	./wait.sh rollout openshift-logging deployment.apps/cluster-logging-operator

.PHONY: netobserv
netobserv: lokistack
	$(STORAGE_SED) $@/lokistack.yaml
	kubectl apply -f $@/
	./wait.sh subscription openshift-netobserv-operator netobserv-operator
	./wait.sh rollout netobserv deployment.apps/loki-gateway

.PHONY: tempo
tempo:
	# Create operator and wait for ready before creating resources.
	kubectl apply -f $@/00_projects.yaml -f $@/10_operators.yaml
	./wait.sh subscription openshift-tempo-operator tempo-product 
	./wait.sh subscription openshift-opentelemetry-operator opentelemetry-product
	kubectl apply -f $@/
	./wait.sh rollout openshift-tracing deployment.apps/tempo-platform-gateway

clean-cluster:
	$(foreach X,$(ALL),kubectl delete --ignore-not-found -f $(X)/ & ) wait


