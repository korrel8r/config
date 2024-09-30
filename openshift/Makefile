
# Deploy operators and resources for observability components.

all: operators resources uiplugins

.PHONY: operators
operators: tempo
	kubectl apply -k operators
	./wait.sh subscription openshift-logging cluster-logging
	./wait.sh subscription openshift-operators-redhat loki-operator
	./wait.sh subscription openshift-netobserv-operator netobserv-operator
	./wait.sh subscription openshift-distributed-tracing jaeger-product
	./wait.sh subscription openshift-opentelemetry-operator opentelemetry-product

# Find default storage class.
DEFAULT_SC=$(shell kubectl get storageclass -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
STORAGE_CLASS?=$(or $(strip $(DEFAULT_SC)),$(error Cannot determine storage class, must set STORAGE_CLASS.))
STORAGE_ENV=resources/storage.env

ifneq ($(STORAGE_CLASS),$(file < $(STORAGE_ENV)))
.PHONY: $(STORAGE_ENV)
endif
$(STORAGE_ENV):
	echo "STORAGE_CLASS=$(STORAGE_CLASS)" > $@

MINIO_ROLLOUT=./wait.sh rollout minio deployment/minio

LOGGING_ROLLOUT=./wait.sh rollout openshift-logging \
deployment.apps/cluster-logging-operator \
deployment.apps/logging-loki-distributor \
deployment.apps/logging-loki-gateway \
deployment.apps/logging-loki-querier \
deployment.apps/logging-loki-query-frontend

NETOBSERV_ROLLOUT=./wait.sh rollout netobserv \
deployment.apps/loki-distributor \
deployment.apps/loki-gateway \
deployment.apps/loki-querier \
deployment.apps/loki-query-frontend \
deployment.apps/netobserv-plugin

.PHONY: resources
resources: $(STORAGE_ENV)
	kubectl apply -k resources
	$(MINIO_ROLLOUT)
	$(LOGGING_ROLLOUT)
	$(NETOBSERV_ROLLOUT)

.PHONY: tempo
tempo:
	kubectl apply -f tempo/base
	./wait.sh subscription openshift-tempo-operator tempo-product

.PHONY: uiplugins
uiplugins:
	kubectl apply -f uiplugins

clean-operators:
	kubectl delete --ignore-not-found -k operators

clean-resources:
	test -f $(STORAGE_ENV) || echo STORAGE_CLASS=dummy > $(STORAGE_ENV) # Kustomize needs this file.
	trap "rm $(STORAGE_ENV)" EXIT; kubectl delete --ignore-not-found -k resources

clean-all: clean-resources clean-operators


