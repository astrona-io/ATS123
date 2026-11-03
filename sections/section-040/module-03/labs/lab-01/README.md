---
estimated_duration: 30m
---

# Split A Broad Policy By Team

- **ID:** LAB
- **Slug:** ats-123-lab-040-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Starting state: the broad policy all-images trusts only the lab key for the whole registry; inventory 6.15.0 is signed with the lab key and 6.14.0 is unsigned; tools 6.15.0 is signed with the tools key and tools 6.14.1 with the lab key; the Secret tools-public-key holds the tools public key.
Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-123-lab-040-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-lab-040-03`), not
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
