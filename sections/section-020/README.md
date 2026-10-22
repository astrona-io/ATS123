# Section 020: Key-Based Policies

The simplest rule Policy Controller can enforce is "only images signed with our key". The release pipeline holds a private key and signs every image it publishes, and the cluster trusts the matching public key. Anything the pipeline did not sign is refused at admission.

This section builds that rule end to end. You sign images with a cosign key pair in a form Policy Controller can check, then write a `ClusterImagePolicy` with a key authority: which images it covers, where the public key comes from, and whether it refuses or only warns.

**Topic covered:** Key policies

## What you will learn

- Signing an image by digest with a cosign key pair, and where the signature is stored.
- Why the course signs in the classic signature format and without the public transparency log.
- Verifying a key signature with `cosign verify`.
- The parts of a `ClusterImagePolicy`: `images`, `authorities`, `mode`.
- Key authorities with `data`, `secretRef` and `kms`.
- How image globs match, and why a typo means "matches nothing".
- Running a policy in `warn` mode and reading its warnings.

## The learning path

The section has one module with a landing page, two short parts, a graded lab right after the second part, and a summary. The landing page starts the module's playground.

### 1. Require Images Signed With Your Key

The playground has Policy Controller running with no policy, `prod` opted in, and two unsigned images in the lab registry.

1. Signing Images For The Cluster
2. Key Authorities In A ClusterImagePolicy, followed by the lab **Write A Key-Based Image Policy**
3. Summary

## Section capstone: Repair A Key Policy That Lets Everything Through

A colleague wrote `inventory-signed`, tested it, and found that nothing was ever refused. The policy has a mistyped image pattern, reads an old public key, and only warns, and images that match no policy are admitted with a warning too. Make the policy enforce exactly the lab key. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-123-capstone-020
```
