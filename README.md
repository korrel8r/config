# Configuring Openshift for Observability Experiments

## Pre-requisites

-   Administrative login to an Openshift cluster.
-   Cluster has a default storage class (`oc get sc` shows \"(default)\"
    beside one storage class)

## Logs

### Install operators

**Option 1.** From OperatorHub

Install "Red Hat Openshift Logging" and "Loki operator"

-   Check "Enable Operator recommended cluster monitoring on this Namespace"
-   Accept all other defaults.

**Option 2:** From source repositories

See instructions in the repository:

-   <https://github.com/openshift/cluster-logging-operator>
-   <https://github.com/grafana/loki/tree/main/operator>

### Create resources

Apply resources in the ./logging directory:

    oc apply -f ./logging

This will create resources in the `openshift-logging` namespace:

1.  A minio deployment to provide S3 storage back-end for LokiStack.
2.  An extra-small LokiStack deployment for log storage and query.
3.  A CluserLogging instance using vector to forward to LokiStack.
4.  A ClusterLogForwarder instance to forward all logs (by default audit logs are not forwarded)

### View logs

Openshift console: Observe > Logs

## Metrics, Alerts

Installed with openshift. 
- Openshift console: Observe

## Events

Built in to k8s. 
- Openshift console: Home > Events 
- Command line: `oc get events`

## Traces

TBD


# Command line and programmatic access to signals

See [signal_samples](./signal_samples/README.md)
