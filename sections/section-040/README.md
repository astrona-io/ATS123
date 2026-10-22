# Section 040: Attestation Policies And Rollout

A signature says who approved an image. It says nothing about how the image was built or what is inside it. Attestations fill that gap: signed statements about an image, such as SLSA provenance that names the build service, or a vulnerability scan result. Policy Controller can require them and check their content before a pod is admitted.

This section adds attestation checks to policies, and then covers the part that decides whether a new policy helps or hurts: rolling it out. You try a policy in warn mode, extend it one namespace at a time, and read the webhook's own messages when it refuses something you did not expect.

**Topic covered:** Attestations and rollout

## What you will learn

- What an in-toto attestation is, and what SLSA provenance and a vulnerability attestation contain.
- Attaching an attestation with `cosign attest` and checking it with `cosign verify-attestation`.
- The `attestations` list of an authority, with `predicateType` and a CUE or Rego `policy`.
- Rolling a policy out with `mode: warn`, the no-match policy and opt-in namespaces.
- Reading why the webhook refused a pod: the error message and the webhook's log.

## The learning path

The section has one module with a landing page, two short parts, a graded lab right after the first part, and a summary. The landing page starts the module's playground.

### 1. Check Attestations And Roll Policies Out

The playground has the key policy `inventory-signed`, two images signed with the lab key, `prod` opted in, and predicate files for provenance and vulnerability scans in the workstation pod.

1. Attestation Policies With CUE And Rego, followed by the lab **Require SLSA Provenance On Inventory Images**
2. Rolling Out Policies And Reading Denials
3. Summary

## Section capstone: Roll Out A Vulnerability Policy Safely

The policy `inventory-vulns` should refuse every `inventory` image with a critical vulnerability finding. It has been in warn mode for a week and has warned on every single image, including clean ones, so nobody trusts it. It was also turned on in `dev` by mistake. Find out why it never matches, fix it, and enforce it in `prod` only. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-123-capstone-040
```
