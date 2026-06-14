# gke-hardener

An installable **agent skill** that makes an AI coding assistant generate a **hardened, secure-by-default GKE cluster** instead of a vanilla one — plus the reference Terraform it emits.

When the skill is installed, asking your agent to "create a GKE cluster" produces a cluster that is hardened *from line one*: private DNS-only control plane, Workload Identity, Binary Authorization, Shielded nodes with Secure Boot, a least-privilege node service account, Dataplane V2 network policy, denied Service `externalIPs`, and optional CMEK Secret encryption + security-bulletin alerts.

> 📖 Companion article: **[add your Medium URL here]**

## What's in here

```
gke-hardener/
├── SKILL.md                 # the skill: trigger + hardening checklist + how-to
├── reference/
│   ├── standard/            # hardened Standard GKE cluster (Terraform module)
│   └── autopilot/           # hardened Autopilot GKE cluster (Terraform module)
├── README.md
└── LICENSE                  # MIT
```

The `reference/*` files are real, `terraform validate`-clean HCL. The skill teaches the agent to **copy and adapt** them into your project — there is no module to `source` from this repo; the validation just proves the reference is correct.

## Install the skill (Claude Code)

User scope (available in every project):

```bash
mkdir -p ~/.claude/skills/gke-hardener
cp -r SKILL.md reference ~/.claude/skills/gke-hardener/
```

Project scope (only this repo):

```bash
mkdir -p .claude/skills/gke-hardener
cp -r SKILL.md reference .claude/skills/gke-hardener/
```

Then in any session: *"create a GKE cluster in Terraform"* → your agent reads the skill and writes a hardened cluster, adapting the reference HCL to your project.

## The reference Terraform

`reference/standard/` and `reference/autopilot/` are the hardened HCL the skill works from. They are meant to be **read and copied into your own Terraform** (where your provider, networking, and variables already live) — not consumed as a remote module. They are kept `terraform validate`-clean so the reference is trustworthy.

> ⚠️ When you adapt them:
> - **`dns_allow_external_traffic` has no default — you must choose.** `true` = remote `kubectl` from anywhere (IAM-gated, no VPN); `false` = control plane reachable only from within Google Cloud (Cloud Shell / bastion / VPN).
> - Private nodes need **Cloud NAT** (egress) + **Private Google Access** (Google APIs).
> - Binary Authorization's default policy is **allow-all** until you author one.
> - Run `terraform plan` against your project — some private-cluster requirements only surface at plan/apply.

## License

[MIT](./LICENSE)
