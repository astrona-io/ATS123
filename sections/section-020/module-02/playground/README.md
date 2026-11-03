# Design Key Policies For A Real Registry — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-123-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Starting state: Policy Controller with no policy; prod opted in; the Secret inventory-public-key holds the lab public key; nothing signed yet.

Built from the documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-123-playground-020-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-123-playground-020-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Installs everything and creates the starting state |
| `manifests/lab-start.yaml` | Namespaces, the lab registry and the workstation pod |
| `manifests/policy-controller-values.yaml` | Helm values for Policy Controller |
| `docs/overview.md` | What the environment contains and ideas to try |
