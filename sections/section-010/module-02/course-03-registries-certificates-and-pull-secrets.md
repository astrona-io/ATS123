# Registries, Certificates And Pull Secrets

The webhook does not read the image from the node. It contacts the registry itself, over the network, to resolve a tag to a digest and to read signatures. This means the webhook needs to trust the registry's certificate and, for a private registry, to be allowed to read. This part shows how both are arranged and how to recognise a failure of either.

## The webhook is a registry client

When a pod asks for `registry.localtest.me:5001/inventory/podinfo:6.15.0`, the webhook sends HTTPS requests to that registry. It asks for the manifest digest of the tag, and later for the signature tag. Go registry clients use plain HTTP only for `localhost` and private addresses, so every other registry must speak HTTPS with a certificate that the webhook trusts.

A public registry uses a certificate from a public authority, and the webhook's base image already trusts those. The lab registry uses a certificate from a lab-only authority, so the chart gets the authority's certificate through a value.

## Trusting a private certificate authority

The value `webhook.registryCaBundle` names a ConfigMap and a key that hold the certificate authority in PEM text. The chart mounts the ConfigMap into the pod and tells the Go runtime to read the extra certificates. Look at the effect in the Deployment:

<!-- astrona:playground:renew -->

```sh
kubectl -n cosign-system get configmap registry-ca -o jsonpath='{.data}' | head -c 120; echo
kubectl -n cosign-system get deployment policy-controller-webhook -o jsonpath='{.spec.template.spec.containers[0].env}' | tr ',' '\n' | grep -i -E 'name|ssl' | head
```

The first command shows the start of the certificate in the ConfigMap `registry-ca`. The second lists environment variables of the webhook container, which include a variable that adds the mounted directory to the places where the runtime looks for authorities. If a registry certificate is not trusted, the webhook log contains an error about an unknown certificate authority, and every image from that registry is refused.

## Credentials for a private registry

A private registry also needs a login. For the image of a pod, Policy Controller uses the pull secrets of the pod and of its service account, the same ones the node would use to pull. It reads them through the Kubernetes API with the permission of its own service account, so the service account must be allowed to read Secrets in the pod's namespace. For signatures stored in another repository, `signaturePullSecrets` on an authority's `source` names Secrets in `cosign-system`.

Find the service account of the webhook, and ask whether it may read Secrets in `prod`:

```sh
SA="$(kubectl -n cosign-system get deployment policy-controller-webhook -o jsonpath='{.spec.template.spec.serviceAccountName}')"
kubectl auth can-i get secrets --as="system:serviceaccount:cosign-system:${SA}" -n prod
```

The answer, `yes` or `no`, tells you if a pull secret in `prod` is reachable. A refusal that says the registry denied access, with no policy name, is an access problem and not a signature problem.

You now know that the webhook is a registry client with its own trust and its own credentials, and how to tell that from a policy failure.

## Common pitfalls

> [!WARNING]
> - **Testing a private registry from your laptop only.** The webhook has its own network path, certificate store and credentials.
> - **Fixing an unknown-authority error by turning off checks.** Add the authority to the bundle.
> - **Putting the pull secret only in `cosign-system`.** A pod's image uses the pod's pull secrets; only `signaturePullSecrets` look in `cosign-system`.
> - **Using HTTP for a registry with a public name.** The client refuses plain HTTP outside local and private addresses.
