CLO=~/src/cluster-logging-operator

logging-bundle: ## Latest CLO with patched logging-view-plugin
	make -C $CLO OVERLAY=$PWD/clo-overlay deploy-image deploy-bundle

logging: ## Run patched CLO bundle.
	oc apply ns openshift-logging
	operator-sdk run bundle -n openshift-logging --install-mode OwnNamespace quay.io/alanconway/cluster-logging-operator-bundle:5.6.0-test.1
	oc apply -f ../logging

log-demo: ## Create bad deployment
	oc delete -f log-demo.yaml --ignore-not-found
	oc apply -f log-demo.yaml

ALERT?=KubeDeploymentReplicasMismatch

install-local:
	cd ../../korrel8; go install ./cmd/korrel8
install-github:
	go install github.com/korrel8/korrel8/cmd/korrel8

alert:
	korrel8 correlate alert/alert loki/infrastructure ?query=$$(urlencode 'alertname=~"$(ALERT)"') --export console
