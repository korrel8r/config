
LIGHTSPEED_TOKEN?=$(error Set LIGHTSPEED_TOKEN to a model API token)
COO_NAMESPACE?=openshift-cluster-observability-operator
RHOAI_API_KEY?=$(LIGHTSPEED_TOKEN)
RHOAI_URL?=https://litellm-litemaas.apps.prod.rhoai.rh-aiservices-bu.com/v1
RHOAI_MODEL?=Qwen3.6-35B-A3B

NS=openshift-lightspeed

all: operator ols

ols:
	cd setup; ./setup-ols.sh

operator:
	oc apply -f 00_namespace.yaml -f 10_lightspeed_operator.yaml

clean:
	oc delete -f 10_lightspeed_operator.yaml -f 00_namespace.yaml
