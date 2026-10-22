# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS123 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Kubernetes Enforcement With Policy Controller**
  domain of the **Sigstore** training path (`ATP023`). It is 15% of the path.
  There is no official Sigstore certification exam; the path's domains and
  weights are Astrona's own, set in `ATP023/path.yaml`.
- **What the domain really tests:** making a Kubernetes cluster refuse images
  that are not signed the way the organisation requires, and proving it. The
  student must *do* things: opt a namespace in, write a `ClusterImagePolicy`
  with a key, a keyless identity or an attestation check, roll it out in
  `warn` mode first, and read why the webhook refused a pod. Every fix is
  proved with an admission request that the webhook allows or denies for the
  right reason.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | How Policy Controller Works | Admission control |
  | 020 | Key-Based Policies | Key policies |
  | 030 | Keyless Policies And Identities | Keyless policies |
  | 040 | Attestation Policies And Rollout | Attestations and rollout |

- **The versions:** `cosign` **v3.1.4**, `regctl` 0.11.7 and Helm **3.22.1**
  as clients; the Sigstore `policy-controller` Helm chart **0.10.8**
  (`appVersion` 0.13.1) with the webhook image overridden to **v0.15.1**
  (`ghcr.io/sigstore/policy-controller/policy-controller@sha256:0492bb264fb1d9bdc8e3f343ef542cc85b7dd7c7fd8d9524b453c2bd31a1d128`).
- **Why v0.15.1 and not the chart default:** v0.15.0 moved the webhook to the
  cosign v3 libraries and go-tuf v2, and v0.14.0 added OCI 1.1 referrers
  discovery. The course signs with cosign v3.1.4. The `v1beta1` schema of the
  `ClusterImagePolicy` CRD in chart 0.10.8 is identical to the one at tag
  v0.15.1 (compared with `yq` and `diff`), so the chart's CRDs fit the newer
  image. If a later chart ships v0.15.x, drop the override.
- **The main sources:** <https://docs.sigstore.dev/policy-controller/overview/>,
  <https://docs.sigstore.dev/policy-controller/installation/>,
  <https://docs.sigstore.dev/policy-controller/sample-policies/>, the
  `policy-controller` source at tag `v0.15.1` (especially
  `pkg/webhook/validator.go`), and the chart in `sigstore/helm-charts`.

### Status: built, not yet run

The first version of this repository was written from the documentation and
source **without a live run**. No playground or lab has been started, and no
`astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

Risks to check first, in this order:

1. **Legacy signatures from cosign v3.1.4.** The environments sign with
   `--new-bundle-format=false --use-signing-config=false --tlog-upload=false`
   (all three flags are deprecated but present at v3.1.4). Check that this
   combination is accepted and writes a classic `sha256-<digest>.sig` tag.
   Why not an empty signing config (`cosign signing-config create`, the
   recommended way to skip Rekor in v3)? At v3.1.4,
   `signcommon.ValidateSigningOptions` refuses a signing config without
   `--new-bundle-format`, and Policy Controller v0.15.1 cannot read the bundle
   format for key authorities. The same validation refuses
   `--tlog-upload=false` together with a signing config, so
   `--use-signing-config=false` is required too. `cosign attest` uses the same
   three flags. The `vuln` predicate must already be in cosign's
   `CosignVulnPredicate` shape (`invocation`, `scanner`, `metadata`); cosign
   ignores other top-level fields.
2. **Key authorities need the legacy format.** At v0.15.1,
   `checkOptsFromAuthority` refuses `signatureFormat: bundle` unless the
   authority is keyless, and a key authority with no `ctlog` skips the
   transparency log check (`IgnoreTlog = true`). Every key-based policy relies
   on both facts.
3. **The keyless example images.** `ghcr.io/stefanprodan/podinfo:6.15.0` was
   signed in its release workflow with cosign from `sigstore/cosign-installer`
   v4.1.2 (cosign v3, so the new bundle format), identity
   `https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.15.0`,
   issuer `https://token.actions.githubusercontent.com`. The keyless policies
   set `signatureFormat: bundle` and `enable-oci11: "true"`. Confirm with
   `cosign verify` before the first run; if the signature is in the legacy
   format, drop `signatureFormat: bundle`.
   `ghcr.io/fluxcd/source-controller:v1.9.6` is the "signed by another
   repository" example; it is refused either way.
4. **Server-side dry run.** Graders admit pods with
   `kubectl run --dry-run=server`. The webhooks declare `sideEffects: None`,
   so the API server calls them during a dry run. Confirm the verdicts match a
   real create.
5. **The registry CA.** The webhook trusts the lab registry through the
   chart's `webhook.registryCaBundle` (`SSL_CERT_DIR=/etc/custom-ca:/etc/ssl/certs`).

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Admission webhook | An HTTPS endpoint the API server calls before it stores an object. A mutating webhook may change the object; a validating webhook may only allow or refuse it |
| Policy Controller | The Sigstore admission webhook that resolves image tags to digests and checks signatures and attestations against `ClusterImagePolicy` resources |
| Opt-in label | `policy.sigstore.dev/include=true` on a namespace; only those namespaces are checked |
| `ClusterImagePolicy` (CIP) | A cluster-wide resource with image glob patterns, authorities, an optional policy and a mode |
| Authority | One way a signature can satisfy a policy: `key`, `keyless` or `static` |
| `static` authority | An authority that passes or fails every matching image without checking anything (`action: pass` / `action: fail`) |
| Identity | The `issuer` and `subject` (or their `RegExp` variants) a keyless certificate must contain |
| `ctlog` | In a CIP authority, the Rekor transparency log to check against (despite the name) |
| `TrustRoot` | A resource that holds the keys and certificates of a private Sigstore instance |
| No-match policy | What happens to an image no CIP matches: `deny` (the default), `warn` or `allow`, set as `no-match-policy` in the ConfigMap `config-policy-controller` |
| Mode | `enforce` (refuse) or `warn` (admit, but return a warning) for one CIP |
| Failure policy | What the API server does when it cannot reach the webhook: `Fail` refuses, `Ignore` admits |
| Attestation | A signed in-toto statement about an image, checked in a CIP with a CUE or Rego policy |

### The example workloads

| Name | What it is |
| --- | --- |
| `registry` (namespace `registry`) | `registry:3.1.2` with TLS on port `5001`, reachable inside the cluster as `registry.localtest.me:5001`. The certificate comes from a lab-only certificate authority created at start (Secret `registry-tls`, ConfigMap `registry-ca`) |
| `workstation` (namespace `workstation`) | `alpine:3.22` with `cosign`, `rekor-cli`, `gitsign`, `regctl`, `git`, `curl`, `jq` and `openssl`, trusting the lab CA. Every command on a page runs here |
| Signing key | A cosign key pair made at start in `/work/keys/cosign.key` and `.pub` (password `lab-only-password`), kept in the Secret `inventory-signing-key` (namespace `workstation`) so a pod restart does not lose it. The public key is also in the ConfigMap `inventory-public-key` (namespace `workstation`), and, where a page or task needs it, in the Secret `inventory-public-key` in `cosign-system` that key policies read |
| `policy-controller` (namespace `cosign-system`, Helm release `policy-controller`) | The webhook Deployment `policy-controller-webhook`, configured by the ConfigMap `config-policy-controller` |
| Images | `registry.localtest.me:5001/inventory/podinfo:6.15.0` and `:6.14.1` in every environment, plus `:6.14.0` in sections 020 and 040, copied from `ghcr.io/stefanprodan/podinfo` (`linux/amd64` only). Keyless examples use `ghcr.io/stefanprodan/podinfo:6.15.0` and `ghcr.io/fluxcd/source-controller:v1.9.6` directly |
| Namespaces `prod` and `dev` | Where pods are admitted; `prod` is the one that opts in |

Pages run tools through a helper:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
```

### Environment facts the text must respect

- **The kind node never pulls a lab image.** The node's container runtime
  neither resolves `registry.localtest.me` nor trusts the lab CA, and Astrona
  creates the cluster, so its mirrors cannot be configured. Every admission
  test therefore uses a **server-side dry run**:
  `kubectl -n prod run check --image=<image> --dry-run=server`. The API server
  runs the mutating and validating webhooks and stores nothing. Pages say this
  once and explain that a real `kubectl apply` would also need the node to pull
  the image.
- **Policy Controller reads the registry over HTTPS.** go-containerregistry
  uses HTTP only for `localhost` and private IP addresses, so the lab registry
  has TLS and the webhook trusts the lab CA through
  `webhook.registryCaBundle`.
- **Signatures for key policies are in the legacy format** and are not
  uploaded to the public Rekor log (`--tlog-upload=false`), so lab entries
  never reach the public-good log. Pages explain the flags in one sentence.
- **Keyless examples need internet from the cluster:** the webhook fetches
  the public-good trust root through TUF and reads signatures from `ghcr.io`.
- **CoreDNS:** copy the `rewrite stop` block (with the answer name rewritten
  back) from `sections/section-010/module-01/playground/bootstrap/prepare.sh`;
  never the one-line `rewrite name` form.
- **Many environments start broken on purpose** (a namespace without the
  label, a CIP in `warn` mode, a glob that misses the image, a key from the
  wrong Secret). The fault is the material. Never "fix" it in the bootstrap.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/lab-start.yaml`,
`manifests/policy-controller-values.yaml`, `docs/overview.md`), labs
(`config.yaml`, `README.md`, `prerequisites.md`, `question.md`,
`solution.md`, `bootstrap/01-install-tools.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-workstation.sh`,
`validation/validate-*.sh`) and one capstone per section.

The shared plumbing (install script, manifests, `config.yaml`, author
READMEs, prerequisites, testing scripts and the helper block at the top of
every seed, solution and validation script) was generated once from a script
outside the repository. Change a shared piece in **every** environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS123`, domain `Kubernetes Enforcement With Policy
Controller`, weight `15`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `admission`, `key-policy`, `keyless-policy`,
  `attestation-policy`, `rollout`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `policy-controller`,
  `admission-webhook`, `namespace-opt-in`, `no-match-policy`,
  `failure-policy`, `tag-to-digest`, `dry-run`, `clusterimagepolicy`,
  `image-glob`, `key-authority`, `keyless-authority`, `static-authority`,
  `identity`, `fulcio`, `rekor`, `trustroot`, `warn-mode`, `attestation`,
  `slsa-provenance`, `vuln-attestation`, `cue`, `rego`, `cosign-sign`,
  `cosign-attest`.
- `resources`: 1 to 4 pages on `docs.sigstore.dev` or `slsa.dev`. The only
  place outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-010/module-01/playground
astrona destroy ats-123-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-123-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-123-playground-<section>-<module>`, `ats-123-lab-<section>-<module>`,
`ats-123-capstone-<section>`. Graders check **behaviour**: a dry-run admission
in `prod` is allowed or denied as the task requires, and the same image in
`dev` is still admitted. They reject the plausible but wrong fix: switching the
webhook's failure policy to `Ignore`, setting `no-match-policy: allow`,
leaving a policy in `warn` mode, a `static` `pass` authority, a glob that
matches everything, or removing the namespace label. A lab's `question.md` and
`solution.md` must match what its `validation/` scripts check.

### Where to find trusted sources

- **Policy Controller:** <https://docs.sigstore.dev/policy-controller/overview/>,
  <https://docs.sigstore.dev/policy-controller/installation/>,
  <https://docs.sigstore.dev/policy-controller/sample-policies/>
- **Cosign:** <https://docs.sigstore.dev/cosign/signing/overview/>,
  <https://docs.sigstore.dev/cosign/verifying/verify/>,
  <https://docs.sigstore.dev/cosign/verifying/attestation/>
- **SLSA provenance:** <https://slsa.dev/spec/v1.0/provenance>
- **Source:** `sigstore/policy-controller` at `v0.15.1`,
  `sigstore/helm-charts` (`charts/policy-controller`, chart 0.10.8).
