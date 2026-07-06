
LIGHTSPEED_TOKEN?=$(error Set LIGHTSPEED_TOKEN to a model API token)

NS=openshift-lightspeed

all: operator ols

ols:
	oc delete -n $(NS) --ignore-not-found secret/credentials
	oc create -n $(NS) secret generic credentials --from-literal "apitoken=$(LIGHTSPEED_TOKEN)"
	oc apply -f service-ca-bundle.yaml
	oc apply -f olsconfig.yaml

operator:
	oc apply -f 00_namespace.yaml -f 10_lightspeed_operator.yaml

clean:
	oc delete -f 10_lightspeed_operator.yaml -f 00_namespace.yaml
