# Attestation Policies And Rollout — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-123-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Starting state: The key policy inventory-signed; 6.15.0 and 6.14.1 signed with the lab key; prod opted in; provenance and scan files in /work.

Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-123-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-playground-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Installs everything and creates the starting state |
| `manifests/lab-start.yaml` | Namespaces, the lab registry and the workstation pod |
| `manifests/policy-controller-values.yaml` | Helm values for Policy Controller |
| `docs/overview.md` | What the environment contains and ideas to try |
