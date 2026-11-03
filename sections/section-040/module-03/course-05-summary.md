# Summary

A policy changes every deployment in the cluster, so it is rolled out in small steps that can be undone. After the rollout, the webhook has to be watched like any other component on the critical path of deployments.

## What you learned

A broad policy forces one key to be trusted everywhere. A policy per team, with the team's glob and the team's key, keeps each key to its own repositories. Apply the new policies before you delete the old one, and test both that each team's images pass and that no team's key works in another team's repository.

A staged rollout uses warn mode and the namespace label: warn in a test namespace, warn in production, enforce in the test namespace, enforce everywhere. A stage ends when the warnings show only what you intended to refuse. Removing the opt-in label stops all checks in a namespace and is an emergency step.

Policies belong in version control with review, a server-side dry run of each file, and a list of sample images with expected results. The webhook needs several replicas and a disruption budget, because the failure policy `Fail` turns its outage into a deployment outage. The key facts to remember are these:

- One policy per owner, one trusted key per repository.
- Apply the new policy before deleting the old one.
- Enforce only after the warnings show what you expect.
- The webhook is on the path of every deployment; run more than one replica.

<!-- astrona:playground:destroy -->
