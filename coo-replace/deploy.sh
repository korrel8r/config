#!/bin/bash
# Scale down existing deployment so it won't interfere and create a new deployment
# using the desired images.

NAMESPACE="$(grep '^  namespace:' korrel8r.yaml | cut -d: -f2 -)"
set -x
for D in observability-operator korrel8r troubleshooting-panel; do
  kubectl scale --replicas=0 -n ${NAMESPACE} deployment/$D
done
kubectl apply -f korrel8r.yaml
kubectl apply -f troubleshooting-panel.yaml
