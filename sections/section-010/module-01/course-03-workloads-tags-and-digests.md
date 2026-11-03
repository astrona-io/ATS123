# Workloads, Tags And Digests

A cluster rarely runs bare pods. Teams create Deployments, Jobs and other workload objects, and the pods appear later from controllers. This part shows which objects Policy Controller checks, why it checks them early, and how it treats an image that is already pinned to a digest.

## Which objects the webhooks check

The API server calls Policy Controller for pods and for the workload kinds that contain a pod template: `Deployment`, `ReplicaSet`, `StatefulSet`, `DaemonSet`, `Job` and `CronJob`. A **pod template** is the part of a workload object that describes the pods the controller will create. For each of these objects, Policy Controller reads every image reference in the pod template, including the init containers, and checks each one.

Checking the workload object matters because it moves the refusal to the moment a person or a pipeline applies it. Without that, a Deployment with an unsigned image would be stored, and only the pods that its ReplicaSet tries to create would be refused. The Deployment would look fine while it had no running pods.

Create a namespace that opts in, and ask for a Deployment with the signed image:

<!-- astrona:playground:renew -->

```sh
kubectl create namespace staging
kubectl label namespace staging policy.sigstore.dev/include=true
kubectl -n staging create deployment check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
```

The request succeeds. Now ask for the unsigned image:

```sh
kubectl -n staging create deployment check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The API server refuses the Deployment itself. The error comes from the webhook `policy.sigstore.dev` and names the image and the policy `inventory-signed`, the same way it does for a pod.

## Tags are resolved, digests are checked

A tag is a name that the registry owner can move. When a pod asks for `podinfo:6.15.0`, the mutating webhook asks the registry for the digest that the tag points to at that moment, and writes it into the object. Look at the result on a Deployment:

```sh
kubectl -n staging create deployment check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 \
  --dry-run=server -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The image in the output ends in `@sha256:` and a digest. From now on, the object names exactly one image, so nobody can swap another image under the same tag between the check and the start.

An image that is already written with a digest skips the resolution step, but not the signature check. Build the reference from the registry and ask for it:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
DIGEST="$(ws regctl image digest registry.localtest.me:5001/inventory/podinfo:6.14.1)"
kubectl -n staging run check --image="registry.localtest.me:5001/inventory/podinfo@${DIGEST}" --dry-run=server
```

The unsigned image is refused again, even though no tag was involved. Pinning an image to a digest makes the deployment repeatable, but it does not make the image trusted. Only a signature that a policy accepts does that.

## Namespaces and workload objects

The webhooks look at the namespace of the object, not at the namespace where the pod will run. A Deployment in `staging` is checked because `staging` carries the label. A Deployment in `dev` is not checked, and neither are the pods it creates. That is why an opt-in label on every namespace that runs production workloads is part of the design, and why a missing label is a silent gap.

You now know that Policy Controller checks workload objects and pods alike, that it pins tags to digests, and that a digest alone proves nothing. The open question is how to read the answer when the webhook refuses something.

## Common pitfalls

> [!WARNING]
> - **Testing a Deployment with `kubectl apply` and waiting for pods.** The node cannot pull lab images. Use `--dry-run=server` to get the decision.
> - **Treating a digest-pinned image as approved.** The digest check still needs a signature that a matching policy accepts.
> - **Forgetting init containers.** Every container in the pod template is checked, so one unsigned init container refuses the whole object.
> - **Labelling the namespace after you created the workload.** Objects that already exist are not checked again until they change.
