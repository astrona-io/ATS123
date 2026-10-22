# ATS123 — Kubernetes Enforcement With Policy Controller (Sigstore)

Course material for the **Kubernetes Enforcement With Policy Controller**
domain of the Astrona Sigstore training path
([ATP023](https://github.com/astrona-io/ATP023)), which is **15% of the
path**. Written for **Policy Controller v0.15.1** (Helm chart 0.10.8 with the
image overridden) and **cosign v3.1.4**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Sigstore documentation and the Policy Controller v0.15.1 source.
> None has been started on a cluster, and no lab has passed `astrona test`
> yet. See `CLAUDE.md` for the ranked list of things to check first.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining the section into a single
  scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | How Policy Controller Works | 1 | 1 + capstone | Admission control |
| [020](sections/section-020) | Key-Based Policies | 1 | 1 + capstone | Key policies |
| [030](sections/section-030) | Keyless Policies And Identities | 1 | 1 + capstone | Keyless policies |
| [040](sections/section-040) | Attestation Policies And Rollout | 1 | 1 + capstone | Attestations and rollout |

The order follows how a team adopts Policy Controller: first the frame around
every policy (opt-in, no-match, failure policy), then trust in a key, then
trust in an identity, and last statements about the build, rolled out safely.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Gate Images At Admission With Policy Controller](sections/section-010/module-01/course.md) | 2 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Require Images Signed With Your Key](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Trust Signing Identities Instead Of Keys](sections/section-030/module-01/course.md) | 2 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Check Attestations And Roll Policies Out](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Restore Enforcement After An Outage | webhook at zero replicas, failure policy `Ignore`, `no-match-policy: allow`, `prod` label removed |
| [020](sections/section-020/capstone/labs/lab-01) | Repair A Key Policy That Lets Everything Through | mistyped glob, old key Secret, `mode: warn`, `no-match-policy: warn` |
| [030](sections/section-030/capstone/labs/lab-01) | Fix A Keyless Policy That Trusts Too Much | `.*` identity, glob too narrow, `mode: warn`, `no-match-policy: allow` |
| [040](sections/section-040/capstone/labs/lab-01) | Roll Out A Vulnerability Policy Safely | wrong predicate type, `mode: warn`, `dev` opted in |

---

## The lab environment

Every playground and lab is a **kind** cluster with:

- **Policy Controller v0.15.1** in `cosign-system` (chart 0.10.8, image pinned
  by digest), trusting the lab registry's certificate authority;
- a registry `registry.localtest.me:5001` with TLS from a lab-only certificate
  authority, reached inside the cluster through a CoreDNS rewrite, holding
  copies of `ghcr.io/stefanprodan/podinfo`;
- a `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and a lab-only key
  pair.

The kind node cannot pull the lab images, so every admission test (pages and
graders) uses `kubectl run --dry-run=server`: the API server runs the webhooks
and stores nothing. The keyless examples use public images on `ghcr.io`
signed in GitHub Actions and need outbound internet from the cluster.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final cluster state** with independent checks, and
several of them reject the plausible-but-wrong fix (a failure policy of
`Ignore`, `no-match-policy: allow`, a policy left in warn mode, a `static`
pass authority, a `.*` identity).
