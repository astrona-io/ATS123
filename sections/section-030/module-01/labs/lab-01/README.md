---
estimated_duration: 25m
---

# Require Images Signed By The podinfo Release Workflow

- **ID:** LAB
- **Slug:** ats-123-lab-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Starting state: prod opts in and no policy exists; every ghcr.io image must be signed by the stefanprodan/podinfo release workflow.
Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-123-lab-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-lab-030-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-tools.sh` | Helm, the lab registry, the workstation, the signing key and Policy Controller |
| `bootstrap/02-seed-state.sh` | The starting state of the task |
| `manifests/` | Namespaces, registry, workstation and Helm values |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-workstation.sh` | Waits until the environment answers |
| `validation/` | Grading scripts, one per check |
