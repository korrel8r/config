
LIGHTSPEED_TOKEN?=$(error Set LIGHTSPEED_TOKEN to a model API token)

NS=-n openshift-lightspeed

ols:
	oc delete $(NS) --ignore-not-found secret/oc-token secret/credentials
	oc create $(NS) secret generic oc-token --from-literal "header=Bearer $(shell oc whoami -t)"
	oc create $(NS) secret generic credentials --from-literal "apitoken=$(LIGHTSPEED_TOKEN)"
	oc apply -f service-ca-bundle.yaml
	oc apply -f olsconfig.yaml

operator:
	oc apply -f 00_namespace.yaml -f 10_lightspeed_operator.yaml

all: operator ols
