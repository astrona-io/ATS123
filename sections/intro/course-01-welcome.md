# Welcome To The Course

This course trains you for the **Kubernetes Enforcement With Policy Controller** part of the Astrona **Sigstore** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, Deployments, labels, `kubectl apply` and `kubectl get`. You know what a container image, a tag and a digest are. You have seen `cosign sign` and `cosign verify` at least once. You do not need to know Policy Controller yet. Each new idea is explained the first time it appears.

## What you can do at the end

Signing an image is only half of the work. A signature protects nothing until something refuses the images that are not signed. In Kubernetes, that something is an admission webhook, and Sigstore's is called Policy Controller. This course asks you to make a cluster refuse the wrong images and to prove it.

The course has four topics. The first is **how Policy Controller works**. You will learn to:

- Explain what an admission webhook is and the path a pod takes through Policy Controller.
- Opt a namespace in, and say what happens to images that match no policy.
- Keep the webhook failing closed, so an outage does not open the door.

The second topic is **key-based policies**. You will learn to:

- Sign images for a cluster with a cosign key pair.
- Write a `ClusterImagePolicy` that trusts one public key for one set of images.

The third topic is **keyless policies**. You will learn to:

- Read the issuer and subject of a keyless signature.
- Trust a GitHub Actions workflow of one repository instead of a key.

The fourth topic is **attestations and rollout**. You will learn to:

- Require a SLSA provenance or vulnerability attestation with a CUE or Rego policy.
- Roll a policy out in warn mode first, and read why the webhook refused a pod.

Everything is written for **Policy Controller v0.15.1** and **cosign v3.1.4**.

## The words this course uses

The pages use Kubernetes', Sigstore's and the in-toto project's own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

An **admission webhook** is an HTTPS service that the Kubernetes API server calls before it stores an object, so the service can change or refuse it. **Policy Controller** is Sigstore's admission webhook for container images. A **`ClusterImagePolicy`** is the resource that tells Policy Controller which images to check and what counts as a good signature. An **authority** is one way an image can pass: a public key, a keyless identity, or a fixed pass or fail.

Two Policy Controller settings decide what happens outside your policies:

| Setting | What it decides |
| --- | --- |
| The opt-in label `policy.sigstore.dev/include=true` | Which namespaces Policy Controller checks at all |
| `no-match-policy` | What happens to an image that no `ClusterImagePolicy` matches: deny, warn or allow |

## The example setup in your playground

Every playground and lab runs the same setup. A small image registry runs inside the cluster at `registry.localtest.me:5001`, with copies of the demo application `podinfo`. A pod called `workstation` holds `cosign`, `regctl` and a lab-only cosign key pair, and every command on a page runs there. Policy Controller runs in the namespace `cosign-system`. Two namespaces, `prod` and `dev`, are where you try to start pods.

The cluster's node never pulls the lab images. Instead, you ask the API server to run the admission webhooks on a pod without storing it, with a server-side dry run. That gives you the webhook's real decision in a second. Many labs start with a policy that is wrong on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with how the webhook works, then checks keys, then identities, and ends with attestations and safe rollout.

| Section | What it covers |
| --- | --- |
| 010 | How Policy Controller Works |
| 020 | Key-Based Policies |
| 030 | Keyless Policies And Identities |
| 040 | Attestation Policies And Rollout |

Each section has one module, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
