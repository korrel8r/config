# OpenShift Lightspeed Deployment with Korrel8r

This directory contains configuration for deploying OpenShift Lightspeed with Korrel8r MCP server integration.

## Prerequisites

1. OpenShift cluster access with admin privileges
2. `oc` CLI authenticated to the cluster
3. API token for your LLM provider (OpenAI, RHOAI, etc.)
4. Korrel8r service running (deployed via `make coo` or `make route`)

## Quick Start

### Option 1: Automated Deployment Using Upstream Script (Recommended)

This uses the official `deploy-with-rhoai-korrel8r.sh` script from the lightspeed-operator repository:

```bash
cd /home/spadubid/Documents/Work/code/upstream/config/openshift

# Set your RHOAI/LiteLLM API token
export LIGHTSPEED_TOKEN="your-api-key"

# Or with custom configuration
COO_NAMESPACE=my-namespace \
RHOAI_URL="https://your-litellm-instance.com/v1" \
RHOAI_MODEL="your-model-name" \
make lightspeed
```

The script automatically:
- Checks prerequisites (oc CLI, cluster connection)
- Verifies Korrel8r service exists in the specified namespace
- Deploys the latest operator from source
- Creates the RHOAI API key secret
- Creates OLSConfig with Korrel8r MCP server integration
- Waits for all components to be ready
- Verifies the deployment

### Option 2: Manual Deployment

If you prefer manual control:

```bash
cd /home/spadubid/Documents/Work/code/upstream/config/openshift/lightspeed

# Set your LLM API token
export LIGHTSPEED_TOKEN="your-api-key"

# Deploy operator + OLSConfig
make deploy-manual

# Or with custom COO namespace
COO_NAMESPACE=my-namespace make deploy-manual
```

### Option 3: Deploy from OLM Catalog (Pinned Version)

This deploys version 1.0.10 from the Red Hat operator catalog:

```bash
cd /home/spadubid/Documents/Work/code/upstream/config/openshift/lightspeed

# Deploy operator
make operator-olm

# Wait for operator to be ready
oc wait --for=condition=Available deployment/lightspeed-operator-controller-manager \
  -n openshift-lightspeed --timeout=300s

# Deploy OLSConfig
export LIGHTSPEED_TOKEN="your-api-key"
make ols
```

## Configuration

### Environment Variables

- `LIGHTSPEED_TOKEN` / `RHOAI_API_KEY` (required): API token for your LLM provider (RHOAI LiteLLM or OpenAI)
- `COO_NAMESPACE` (optional): Namespace where korrel8r service is running (default: `openshift-cluster-observability-operator`)
- `KORREL8R_NAMESPACE` (optional): Alias for `COO_NAMESPACE`, used by the upstream script
- `RHOAI_URL` (optional): RHOAI LiteLLM endpoint URL (default: `https://litellm-litemaas.apps.prod.rhoai.rh-aiservices-bu.com/v1`)
- `RHOAI_MODEL` (optional): Model name to use (default: `Qwen3.6-35B-A3B`)
- `LIGHTSPEED_OPERATOR_DIR` (optional): Path to lightspeed-operator source (default: `~/Documents/Work/code/upstream/lightspeed-operator`)

### Korrel8r Integration

The `olsconfig.yaml` is configured to connect to the Korrel8r MCP server using:

- **URL**: `https://korrel8r.openshift-cluster-observability-operator.svc.cluster.local:9443/mcp`
- **Authentication**: Kubernetes service account token (`type: kubernetes`)
- **Timeout**: 30 seconds

The namespace is automatically replaced based on `COO_NAMESPACE`.

### LLM Provider

By default, the configuration uses OpenAI with `gpt-4o-mini`. To use RHOAI or another provider, edit `olsconfig.yaml`:

```yaml
llm:
  providers:
    - credentialsSecretRef:
        name: credentials
      models:
        - name: Qwen3.6-35B-A3B
      name: rhoai
      type: openai
      url: "https://litellm-litemaas.apps.prod.rhoai.rh-aiservices-bu.com/v1"
ols:
  defaultModel: Qwen3.6-35B-A3B
  defaultProvider: rhoai
```

## Verify Deployment

```bash
# Check all pods are running
oc get pods -n openshift-lightspeed

# Expected pods:
# - lightspeed-app-server
# - lightspeed-console-plugin
# - lightspeed-operator-controller-manager
# - lightspeed-postgres-server

# Check OLSConfig status
oc get olsconfig cluster -o yaml

# Check korrel8r MCP server connection
oc logs -n openshift-lightspeed deployment/lightspeed-app-server -c lightspeed-service-api | grep korrel8r
```

## Troubleshooting

### Korrel8r Connection Errors

If you see 404 or connection errors to korrel8r:

1. Verify korrel8r service exists:
   ```bash
   oc get service korrel8r -n openshift-cluster-observability-operator
   ```

2. Check the namespace matches your `COO_NAMESPACE`:
   ```bash
   oc get olsconfig cluster -o yaml | grep korrel8r
   ```

3. Verify service CA bundle:
   ```bash
   oc get configmap service-ca-bundle -n openshift-lightspeed
   ```

### LLM Connection Issues

Check app server logs:
```bash
oc logs -n openshift-lightspeed deployment/lightspeed-app-server -c lightspeed-service-api | grep -i error
```

Verify credentials secret:
```bash
oc get secret credentials -n openshift-lightspeed -o yaml
```

## Uninstall

```bash
# Delete OLSConfig (removes all app components)
oc delete olsconfig cluster

# Undeploy operator (if deployed from source)
make -C lightspeed undeploy

# Or delete operator manually (if deployed from OLM)
oc delete -f lightspeed/10_lightspeed_operator.yaml
oc delete namespace openshift-lightspeed
```

## Files

- `olsconfig.yaml` - OLSConfig custom resource with korrel8r MCP server
- `10_lightspeed_operator.yaml` - Operator subscription (OLM catalog version)
- `00_namespace.yaml` - Namespace definition
- `service-ca-bundle.yaml` - Service CA bundle configmap
- `Makefile` - Deployment automation

## References

- [Upstream lightspeed-operator](https://github.com/openshift/lightspeed-operator)
- [OpenShift Lightspeed Service](https://github.com/openshift/lightspeed-service)
- [Korrel8r Documentation](https://korrel8r.github.io/korrel8r/)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
