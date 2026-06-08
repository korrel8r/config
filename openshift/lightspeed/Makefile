
LIGHTSPEED_TOKEN?=$(error Set LIGHTSPEED_TOKEN to a model API token)
COO_NAMESPACE?=openshift-cluster-observability-operator
LIGHTSPEED_OPERATOR_DIR?=$(HOME)/Documents/Work/code/upstream/lightspeed-operator
RHOAI_API_KEY?=$(LIGHTSPEED_TOKEN)
RHOAI_URL?=https://litellm-litemaas.apps.prod.rhoai.rh-aiservices-bu.com/v1
RHOAI_MODEL?=Qwen3.6-35B-A3B

NS=-n openshift-lightspeed

# Deploy using upstream automated script (RECOMMENDED)
all: deploy-automated

# Automated deployment using upstream script
deploy-automated:
	@if [ ! -f "$(LIGHTSPEED_OPERATOR_DIR)/config/samples/deploy-with-rhoai-korrel8r.sh" ]; then \
		echo "Error: deploy script not found at $(LIGHTSPEED_OPERATOR_DIR)/config/samples/deploy-with-rhoai-korrel8r.sh"; \
		exit 1; \
	fi
	cd $(LIGHTSPEED_OPERATOR_DIR) && \
	RHOAI_API_KEY=$(RHOAI_API_KEY) \
	RHOAI_URL=$(RHOAI_URL) \
	RHOAI_MODEL=$(RHOAI_MODEL) \
	KORREL8R_NAMESPACE=$(COO_NAMESPACE) \
	./config/samples/deploy-with-rhoai-korrel8r.sh

# Manual deployment steps (alternative to automated script)
ols:
	oc delete $(NS) --ignore-not-found secret/credentials
	oc create $(NS) secret generic credentials --from-literal "apitoken=$(LIGHTSPEED_TOKEN)"
	oc apply -f service-ca-bundle.yaml
	sed 's/openshift-cluster-observability-operator/$(COO_NAMESPACE)/g' olsconfig.yaml | oc apply -f -

# Deploy latest operator from upstream source manually
operator:
	@if [ ! -d "$(LIGHTSPEED_OPERATOR_DIR)" ]; then \
		echo "Error: lightspeed-operator directory not found at $(LIGHTSPEED_OPERATOR_DIR)"; \
		echo "Set LIGHTSPEED_OPERATOR_DIR to the correct path"; \
		exit 1; \
	fi
	$(MAKE) -C $(LIGHTSPEED_OPERATOR_DIR) deploy

# Deploy operator from OLM catalog (pinned version)
operator-olm:
	oc apply -f 00_namespace.yaml -f 10_lightspeed_operator.yaml

# Manual deployment (operator + ols config)
deploy-manual: operator ols

# Clean up
undeploy:
	oc delete olsconfig cluster || true
	$(MAKE) -C $(LIGHTSPEED_OPERATOR_DIR) undeploy
