# Staged Rollouts With Warn Mode

Warn mode lets a policy report what it would refuse. A staged rollout uses it on purpose, one namespace at a time. This part describes the stages, the signals to watch in each, and the point at which a stage may end.

## The stages

A staged rollout of a new policy has four stages, and each one ends with a check that a person can read:

1. **Warn in a test namespace.** Opt in a namespace that holds only test workloads, set `mode: warn` and deploy the usual workloads. Read the warnings.
2. **Warn in production.** Opt in the production namespace with the same policy still in warn mode. Real workloads now produce real warnings.
3. **Enforce in the test namespace.** Switch the policy to enforce and keep the production namespace on a copy of the policy in warn mode, or opt the production namespace out for the moment.
4. **Enforce everywhere.** Remove the warn copy and opt the remaining namespaces in.

<!-- astrona:playground:renew -->

You can model the stages with namespace labels. Create two namespaces and opt only one in:

```sh
kubectl create namespace stage-test
kubectl create namespace stage-prod
kubectl label namespace stage-test policy.sigstore.dev/include=true
kubectl -n stage-test run check --image=registry.localtest.me:5001/tools/podinfo:6.14.1 --dry-run=server
kubectl -n stage-prod run check --image=registry.localtest.me:5001/tools/podinfo:6.14.1 --dry-run=server
```

The first is checked by the policies and the second is not checked at all, because `stage-prod` has not opted in. The label is the switch for each namespace, which makes the label the main tool of a staged rollout.

## What ends a stage

A stage ends when the warnings contain only what you intended to refuse. Three questions decide it:

- Does every warning name an image that should be refused?
- Does every image that should pass run without a warning?
- Has every team that deploys into the namespace been told and had a chance to fix its images?

If one answer is no, stay in the stage and fix the cause, which is either the policy or the image.

## Roll back by label

The label also makes the way back short. Removing `policy.sigstore.dev/include` from a namespace stops all checks there at once. Use it when an enforced policy blocks something critical. Then correct the policy, return to warn mode and start the stage again:

```sh
kubectl label namespace stage-test policy.sigstore.dev/include-
```

> [!IMPORTANT]
> Removing the label removes all protection from that namespace, not only from one policy. Treat it as an emergency step, record it, and restore the label when the cause is fixed.

## Common pitfalls

> [!WARNING]
> - **Skipping the warning stage because the policy looks right.** Real workloads use images you did not think of.
> - **Reading warnings only once.** Check across a full release cycle, including jobs that run weekly.
> - **Opting every namespace in at the same time.** One mistake then blocks everything.
> - **Leaving a policy in warn mode forever.** It then protects nothing.
