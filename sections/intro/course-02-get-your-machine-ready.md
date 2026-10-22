# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster.
- **The astrona command-line tool.**
- **`jq`:** reads JSON, so you can pick out one field of a policy or a signature.

You do not install `cosign` yourself. Every environment starts a pod called `workstation` with **`cosign` v3.1.4**, `regctl`, `jq` and `openssl`, and every Sigstore command on a page runs there. The environment also puts **Helm 3.22.1** in `/usr/local/bin` or `~/.local/bin` to install Policy Controller.

The playgrounds and labs need **outbound internet** while they start and while you work. They download Helm and the Sigstore tools, pull the Policy Controller image, and copy `podinfo` from `ghcr.io`. Policy Controller also reads the public Sigstore trust root and public signatures for the keyless examples. Without outbound internet, those steps fail with errors that have nothing to do with Policy Controller.

## Working in the workstation pod

Every page that runs `cosign` or `regctl` uses one of two forms. For one command, it defines a short helper and calls it:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws cosign version
```

For several commands in a row, open a shell in the pod and type them there:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside the pod, the lab registry answers at `registry.localtest.me:5001` with a certificate from a lab-only certificate authority that the pod already trusts. The lab-only key pair is in `/work/keys`, and its password is `lab-only-password`. A real setup never shares a signing password on a page.

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman. Install `jq` yourself.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It asks the API server to admit pods in `prod` and `dev` with a dry run and reads your policies, so your fix has to actually work, not only make a warning go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-123-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own registry and webhook. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If every pod you try is refused, read the message: a namespace that opts in refuses every image that no policy matches, and that is often the point of the page. Remember also that a lab that starts with a policy in the wrong state is broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
