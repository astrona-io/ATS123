# Monitoring The Webhook

The webhook sits in front of every create and update in the opted-in namespaces. If it is slow, deployments are slow, and if it is down with the failure policy `Fail`, deployments stop. This part describes what to watch and what to do when the webhook misbehaves.

## Logs

The webhook logs each failed check as a JSON line. Read the recent ones, filtered for problems:

<!-- astrona:playground:renew -->

```sh
kubectl -n cosign-system logs deploy/policy-controller-webhook --since=15m | grep -i -E 'error|fail|warn'
```

A line names the image digest and the policy. Count the lines for one policy to see how often it refuses, and look for the same digest repeated, which shows a deployment that keeps retrying.

## Availability

With the failure policy `Fail`, the API server rejects requests when it cannot reach the webhook. Two settings decide how often that happens:

- **Replicas.** One replica means any restart is an outage. Run at least two, and spread them across nodes with a pod anti-affinity or a topology spread rule.
- **Disruption budget.** A PodDisruptionBudget keeps node drains from removing all replicas at once.

Check the current state:

```sh
kubectl -n cosign-system get deployment policy-controller-webhook
kubectl -n cosign-system get pods -o wide
```

Do not exempt `cosign-system` from the checks by removing the label from a namespace that matters; keep the label off `cosign-system` and `kube-system`, as the first module explained, so the webhook can always restart.

## Latency

Each check calls the registry, so a slow registry makes admission slow. Signature lookups are cached for a short time, but the first check of a new digest is not. If deployments time out at admission, test the registry from the workstation pod and compare the time with `time cosign verify`.

## When an image must run anyway

Sometimes an unsigned image must run during an incident. A safe procedure has these properties: it is slow enough that nobody does it by accident, it affects one namespace or one policy, and it leaves a record. A common form is a separate namespace without the opt-in label, created for the incident and deleted afterwards, with the change recorded in the incident log. Do not change the no-match policy or the failure policy for this; those settings affect the whole cluster.

## Common pitfalls

> [!WARNING]
> - **One webhook replica.** Every restart blocks deployments.
> - **Watching only the pods.** A running pod can still answer slowly or fail on the registry.
> - **Fixing an incident by editing the failure policy.** It removes the protection for the whole cluster.
> - **Forgetting to undo the emergency path.** Delete the incident namespace and restore the label.
