# What The Chart Installs

Before you change a component, list what it consists of. Policy Controller arrives as one Helm release, and a few commands show every object it created. This part reads the release, the custom resource definitions, the workload and the webhook configurations, so that you know where each setting lives.

## The Helm release

Helm is a package manager for Kubernetes. A **chart** is a package of templates, and a **release** is one installation of a chart in a cluster. List the releases in the namespace of Policy Controller:

<!-- astrona:playground:renew -->

```sh
helm list -n cosign-system
```

The output shows the release `policy-controller`, the chart version `policy-controller-0.10.8` and the app version of the chart. The webhook image in this course is newer than the chart's app version, because the values file overrides it.

## Custom resources

A **custom resource definition** (CRD) teaches the API server a new kind of object. Policy Controller adds the kinds that make up its API:

```sh
kubectl get crd | grep sigstore
```

The list contains `clusterimagepolicies.policy.sigstore.dev`, the kind of object you write policies in, and `trustroots.policy.sigstore.dev`, the kind that describes the keys and certificates of a private Sigstore instance. Because these are cluster-wide kinds, a policy has no namespace.

## The workload and its configuration

The chart creates a Deployment, a Service, a service account and several ConfigMaps in `cosign-system`:

```sh
kubectl -n cosign-system get deployment,service,serviceaccount,configmap
```

The Deployment `policy-controller-webhook` runs the webhook. The ConfigMap `config-policy-controller` holds the settings you will change. The ConfigMap `config-image-policies` holds the compiled form of each `ClusterImagePolicy`, which the webhook writes itself. Do not edit that one.

## The webhook configurations

The last group of objects tells the API server to call the webhook:

```sh
kubectl get mutatingwebhookconfigurations,validatingwebhookconfigurations | grep sigstore
```

`policy.sigstore.dev` exists once as a mutating and once as a validating configuration. Two more configurations with `clusterimagepolicy` in their names check the policies you apply, and refuse a policy with an invalid field before it is stored.

Check the pieces together with the manifest that Helm keeps. This prints the kind and name of every object in the release:

```sh
helm get manifest policy-controller -n cosign-system | grep -E '^(kind|  name):' | paste - - | sort | uniq
```

You now know the objects behind Policy Controller and which two are central: the Deployment that runs the checks and the ConfigMap with its settings. The next question is how those settings reach the ConfigMap.

## Common pitfalls

> [!WARNING]
> - **Editing a ConfigMap or Deployment with `kubectl edit`.** The next `helm upgrade` writes the chart's values back.
> - **Deleting a CRD to clean up.** Deleting `clusterimagepolicies.policy.sigstore.dev` deletes every policy.
> - **Reading `helm list` as the running version.** The app version is the chart's default; the image that runs can be overridden.
> - **Editing `config-image-policies`.** The webhook owns it and overwrites your change.
