# Signal sample data

A collection of observability signal samples in JSON format.

`*.json` files: contain a series of JSON objects (not a JSON array, just the objects)
where each object represents a single instance of the given signal type.

## Accessing and generating data

Makefile: contains commands used to generate the data.
You need to be logged in to an openshift cluster as kubeadmin, with openshift logging installed.

The samples are not representative of the variety of signals, and are not well organized - this will improve
They are useful to get a feel for the basic structure of the signal data.

## Data model documentation

- ViaQ log format (upstream), used by openshift logging: https://github.com/ViaQ/documentation

## Tracing notes

Useful links:
- [Access the Jaeger REST API programatically in OpenShift](https://dev.to/iblancasa/access-the-jaeger-rest-api-programatically-in-openshift-ebk)
- [Using OpenTracing and Jaeger with Your Own Services/Application – Open Sourcerers](https://www.opensourcerers.org/2022/05/30/using-opentracing-and-jaeger-with-your-own-services-application/)
- Disabling authentication (see hack/jaeger.yaml): `spec.ingress.security: none`
