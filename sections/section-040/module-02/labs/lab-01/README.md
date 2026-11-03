---
estimated_duration: 25m
---

# Require An Approved Review

- **ID:** LAB
- **Slug:** ats-123-lab-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Starting state: inventory-signed only checks the lab key; all three images are signed; 6.15.0 has an approved review attestation, 6.14.1 a rejected one, 6.14.0 none.
Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-123-lab-040-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-lab-040-02`), not
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
