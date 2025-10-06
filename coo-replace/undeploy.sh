#!/bin/bash
# Undo the actions of deploy.sh

NAMESPACE="$(grep '^  namespace:' korrel8r.yaml | cut -d: -f2 -)"
set -x
kubectl delete -f troubleshooting-panel.yaml
kubectl delete -f korrel8r.yaml
for D in observability-operator korrel8r troubleshooting-panel; do
  kubectl scale --replicas=1 -n ${NAMESPACE} deployment/$D
done
