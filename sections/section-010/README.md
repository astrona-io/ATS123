# Section 010: How Policy Controller Works

A signed image protects nothing on its own. Kubernetes starts any image you name, signed or not, unless something in the path between `kubectl apply` and the stored pod refuses it. That something is an admission webhook, and Sigstore's admission webhook for images is Policy Controller.

This section explains the path a pod takes through Policy Controller and the settings that decide its fate before any signature is checked. Policy Controller only checks namespaces that opt in with a label, refuses images that no policy matches unless you say otherwise, and relies on the API server to refuse pods when the webhook cannot be reached. Get those three settings wrong and the best policy does nothing.

**Topic covered:** Admission control

## What you will learn

- What an admission webhook is, and the difference between a mutating and a validating webhook.
- How Policy Controller resolves an image tag to a digest and why it checks the digest.
- Which namespaces Policy Controller checks, and how the opt-in label works.
- What the no-match policy does to images that no `ClusterImagePolicy` matches.
- Why the webhook's failure policy must be `Fail`, and what `Ignore` costs during an outage.
- How to ask for an admission decision with a server-side dry run.

## The learning path

The section has one module. It has a landing page, two short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Gate Images At Admission With Policy Controller

The playground has Policy Controller running, the key-based policy `inventory-signed`, and the signed image `registry.localtest.me:5001/inventory/podinfo:6.15.0`. The namespace `prod` does not opt in yet.

1. Admission Webhooks And The Policy Controller Flow
2. Opting Namespaces In And Failing Closed, followed by the lab **Enforce Signatures In The prod Namespace**
3. Summary

## Section capstone: Restore Enforcement After An Outage

The capstone is one graded scenario that combines the whole module. During an outage of the webhook, someone made the cluster admit everything again: the webhook runs no pods, its failure policy says `Ignore`, images that match no policy are allowed, and `prod` no longer opts in. Find every workaround and undo it. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-123-capstone-010
```
