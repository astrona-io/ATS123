---
estimated_duration: 30m
---

# Repair A Key Policy That Lets Everything Through

- **ID:** CAPSTONE
- **Slug:** ats-123-capstone-020
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Starting state: inventory-signed has a mistyped glob, reads the old key from old-signing-key and runs in warn mode, and no-match-policy is warn.
Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-123-capstone-020
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-capstone-020`), not
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
