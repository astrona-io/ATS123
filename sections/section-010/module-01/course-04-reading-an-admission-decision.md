# Reading An Admission Decision

When the webhook refuses a request, the person who ran the command sees one error and has to work out what to change. This part teaches how to read that error, how to find more detail in the webhook's log, and how to tell the five usual reasons for a refusal apart.

## The anatomy of an error

A refusal comes back from the API server as an error that starts with the name of the webhook, `policy.sigstore.dev`, and the word `denied`. After that, the message lists one entry per failed check. Each entry has the same parts: the field that holds the image, for example `spec.containers[0].image`, the image written with its digest, and the text of the failure. For a failed policy the text names the `ClusterImagePolicy`, and then the authority, so you can tell which rule refused which image.

Reproduce a refusal and read it. The playground has `inventory-signed` and an unsigned `6.14.1`:

<!-- astrona:playground:renew -->

```sh
kubectl create namespace review
kubectl label namespace review policy.sigstore.dev/include=true
kubectl -n review run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

Find the field path, the image digest, the policy name and the authority name in the message. If an image appears in two places in a pod, the message lists the field of each one.

## The five usual reasons

Most refusals are one of five cases, and the message wording tells which. An image that matches no policy is refused with a message that says no policy matched, and it does not name a policy, because none applied. An image that matches a policy but has no signature is refused with the policy and authority named and a note that no signature was found. An image with a signature from another key or identity names the same authority and says the signature did not verify. An image whose registry the webhook cannot reach gives a network or certificate error from the registry, not a policy error. An attestation that fails names the attestation entry and the policy language, CUE or Rego.

Test the first case with an image that no policy covers:

```sh
kubectl -n review run check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

This time no policy name appears. That tells you to look at the image patterns, not at the keys.

## The webhook log

The webhook writes a JSON log line for each failed check. Read the last few minutes and filter for failures:

```sh
kubectl -n cosign-system logs deploy/policy-controller-webhook --since=5m | grep -i -E 'error|fail|warn'
```

Each line has a timestamp and a message, and the failing image digest appears in it. When a registry error is the cause, the log shows the registry address and the error text from the HTTP request, which the client-side message may shorten. The log is also where you see that the webhook started and loaded its policies.

Count the policies the webhook knows. The webhook keeps them in a ConfigMap that it creates itself:

```sh
kubectl get clusterimagepolicy
kubectl -n cosign-system get configmap config-image-policies -o jsonpath='{.data}' | head -c 400; echo
```

The ConfigMap `config-image-policies` holds a compiled copy of every `ClusterImagePolicy`. If a policy appears in the first command and its name is missing from the second, the webhook has not picked it up yet, and a retry after a few seconds is the right next step.

## A short method

Work in the same order every time. Read the policy name in the error, or notice that there is none. Print that policy with `kubectl get clusterimagepolicy <name> -o yaml` and check the `images` globs against the image name in the message. Check the key or identity with `cosign verify` in the workstation pod. Only then change the policy, and try the same dry run again.

You can now turn an error message into a short list of causes and tests. What remains in this section is the frame around the policies: how the controller itself is installed and configured.

## Common pitfalls

> [!WARNING]
> - **Looking for a Kubernetes event.** A refused request is never stored, so no event or pod exists. Read the error and the webhook log.
> - **Changing the key before checking the glob.** A message without a policy name means no policy matched, and a different key cannot fix that.
> - **Reading only the first line of a long error.** An object with several images lists a failure for each one.
> - **Assuming a stale policy list.** A new policy takes a few seconds to reach the webhook, so retry once before you change anything.
