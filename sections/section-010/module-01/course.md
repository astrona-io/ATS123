# Gate Images At Admission With Policy Controller

You can sign every image your team builds, and Kubernetes will still start an unsigned one if someone asks for it. The signature only matters when something checks it at the moment a pod is created. In Kubernetes, the component that can refuse an object before it is stored is an admission webhook.

Policy Controller is Sigstore's admission webhook for container images. It turns every image in a pod into a reference by digest, finds the `ClusterImagePolicy` resources that match it, and checks the signatures and attestations those policies require. Keep one sentence in mind: **Policy Controller only protects namespaces that opt in, and only while the API server refuses pods it cannot check.**

The module has two parts. **Admission Webhooks And The Policy Controller Flow** follows one pod through the API server and the two webhooks, and shows how to ask for a decision with a server-side dry run. **Opting Namespaces In And Failing Closed** covers the three settings around every policy: the opt-in label, the no-match policy and the failure policy. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain what a mutating and a validating admission webhook do, and which one Policy Controller uses for what.
- Explain why Policy Controller replaces an image tag with a digest.
- Ask the API server for an admission decision with `kubectl run --dry-run=server`.
- Opt a namespace in to Policy Controller and leave another namespace out.
- Say what happens to an image that matches no `ClusterImagePolicy`, and change it.
- Explain why the webhook's failure policy must be `Fail`.

## Before you start

You need Kubernetes basics: namespaces, pods, labels, `kubectl apply` and `kubectl get`. You need to know what an image tag and an image digest are. You do not need to write a policy yet; the playground already has one.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** in the namespace `cosign-system`. A registry inside the cluster answers at `registry.localtest.me:5001` and holds `inventory/podinfo:6.15.0` (signed with the lab key) and `inventory/podinfo:6.14.1` (not signed). The `ClusterImagePolicy` named `inventory-signed` requires the lab key for every image under `registry.localtest.me:5001/inventory/`. The namespaces `prod` and `dev` exist, and neither opts in yet.

The `workstation` pod holds `cosign`, `regctl` and `jq`, and every Sigstore command in this module runs there. The cluster's node never pulls the lab images, so you ask for admission decisions with a server-side dry run, as the parts show.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
