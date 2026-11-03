# Rolling Policies Out And Operating Them — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-123-playground-040-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Starting state: the broad policy all-images trusts the lab key for the whole registry; inventory images are signed with the lab key and tools images with a separate tools key; prod opted in.

Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-123-playground-040-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-playground-040-03`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Installs everything and creates the starting state |
| `manifests/lab-start.yaml` | Namespaces, the lab registry and the workstation pod |
| `manifests/policy-controller-values.yaml` | Helm values for Policy Controller |
| `docs/overview.md` | What the environment contains and ideas to try |
