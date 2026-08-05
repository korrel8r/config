# Setting up lightspeed

* [setup-ols.sh script from pull request](https://github.com/rhobs/troubleshooting-scenarios/pull/42/changes#diff-dfa7d444c4d336376f3968e4cf7c5ff45add79acda23c3d2e3d5ccb85afc2038)
* [Configure | Red Hat OpenShift Lightspeed | 1.0 | Red Hat Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/1.0/html/configure/ols-configuring-integrating-google-vertex-ai#ols-configuring-proc-configuring-google-vertex-ai_ols-configuring-integrating-google-vertex-ai)

My env settings, may not all be required:

``` bash
export GCP_PROJECT_ID=itpc-gcp-hcm-pe-eng-claude
export GCP_SERVICE_ACCOUNT_JSON=~/.config/gcloud/application_default_credentials.json
export OLS_DEFAULT_PROVIDER=anthropic
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=$GCP_PROJECT_ID
export CLAUDE_CODE_USE_VERTEX=1
```

Run

``` bash
setup-ols.sh
```

`
