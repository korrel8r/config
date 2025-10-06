# Replace korrel8r and troubleshooting panel deployed by COO.

**For debugging and development purposes**

The scripts are for use with the Cluster Observability Operator.
They scale down the COO-managed deployments of korrel8r and the troubleshooting-panel,
and create replacement deployments running the images of your choice.

To replace the deployments
    ./deploy.sh

To restore the original deployments
    ./undeploy.sh


The YAML files will use these images by default:
 - quay.io/alanconway/korrel8r
 - quay.io/alanconway/troubleshooting-panel-console-plugin

Edit the YAML files to use different images.
