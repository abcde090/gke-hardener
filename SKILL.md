---
name: gke-hardener
description: Use when writing, generating, or reviewing Terraform (or gcloud) for a Google Kubernetes Engine (GKE) cluster or node pool. Emits a hardened, secure-by-default cluster — private DNS-only control plane, Workload Identity, Binary Authorization, Shielded nodes with Secure Boot, least-privilege node service account, Dataplane V2 network policy, deny Service externalIPs, plus optional CMEK Secret encryption and security-bulletin alerts. Reach for this whenever a GKE cluster is being created so it is hardened from line one.
---

# GKE Hardener

When the user asks you to create or modify a GKE cluster — a Terraform `google_container_cluster` / `google_container_node_pool`, or a `gcloud container clusters create` command — **do not emit a default cluster.** A default GKE cluster ships with a public control-plane endpoint, the broadly-privileged Compute Engine node service account, a legacy kubelet read-only port, and no image-admission policy. Generate a hardened one instead, using the patterns below.

## Step 0 — prefer Autopilot when you can

If the user has no hard requirement to manage node pools themselves, recommend **Autopilot**. It enforces the node and runtime layers by default: no node SSH, Shielded nodes, Workload Identity, Container-Optimized OS with auto-upgrade, a hardened Pod admission policy (Baseline + many Restricted constraints), `RuntimeDefault` seccomp, and Service `externalIPs` blocked.

**Autopilot is not "secure by itself."** You still configure, on Autopilot or Standard alike:
- **Private networking** — Autopilot defaults to **public nodes and a public control-plane endpoint**.
- **A custom least-privilege node service account** — Autopilot defaults to the **Compute Engine default SA**. In Terraform you must set it in **both** `node_config.service_account` **and** `cluster_autoscaling.auto_provisioning_defaults.service_account`.
- **Binary Authorization**, **CMEK Secret encryption**, and **security-bulletin notifications**.

Use `reference/autopilot/` for a hardened Autopilot cluster, or `reference/standard/` for a hardened Standard cluster.

## The hardening checklist (Standard clusters)

1. **Control plane by identity, not IP** — `private_cluster_config { enable_private_nodes = true }`, and `control_plane_endpoints_config { dns_endpoint_config { allow_external_traffic = <true|false> } ip_endpoints_config { enabled = false } }`. (Private nodes and the private control-plane endpoint are *two separate switches* — set both. Private nodes also need **Cloud NAT** for egress + **Private Google Access**.) **`allow_external_traffic` is a deliberate choice:** `true` = remote `kubectl` from anywhere, IAM-gated, no VPN; `false` = control plane reachable only from within Google Cloud (Cloud Shell / bastion / VPN). Ask the user which they want.
2. **Workload Identity** — `workload_identity_config { workload_pool = "<project>.svc.id.goog" }`, plus `node_config.workload_metadata_config.mode = "GKE_METADATA"` on the node pool.
3. **Binary Authorization** — `binary_authorization { evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE" }`. Note the **default policy is allow-all** — you must author the policy + attestors (and wire Artifact Analysis for scanning) or enforcement admits everything.
4. **Minimal node surface** — `enable_shielded_nodes = true`; on the node pool `shielded_instance_config { enable_secure_boot = true; enable_integrity_monitoring = true }`; a **least-privilege node SA** (`roles/container.defaultNodeServiceAccount`, never the default Compute Engine SA); `node_pool_defaults.node_config_defaults.insecure_kubelet_readonly_port_enabled = "FALSE"`; `master_auth.client_certificate_config.issue_client_certificate = false`; `service_external_ips_config { enabled = false }`; node `management { auto_repair = true; auto_upgrade = true }` on Container-Optimized OS.
5. **Encrypt Secrets with your own key** — `database_encryption { state = "ENCRYPTED"; key_name = <your Cloud KMS key> }`. The key becomes load-bearing (a disabled key blocks Secret reads; rotation doesn't re-encrypt existing Secrets).
6. **Security-bulletin notifications** — `notification_config { pubsub { enabled = true; topic = <topic>; filter { event_type = ["SECURITY_BULLETIN_EVENT"] } } }`.

**Runtime guardrails** (defense in depth after creation): Dataplane V2 network policy (`datapath_provider = "ADVANCED_DATAPATH"` + default-deny `NetworkPolicy`), Pod Security Standards `restricted` via the PodSecurity admission controller, `seccompProfile: RuntimeDefault` on pods, **RBAC least privilege** (no `cluster-admin`/wildcards; restrict `pods/exec` and `secrets`), and **Cloud Audit Data Access logs** exported to a security-owned sink.

## How to apply

1. Read the hardened reference HCL in `reference/standard/` (or `reference/autopilot/`) and **copy/adapt it into the user's own Terraform** — fit it to their existing provider, network/subnetwork, and variable conventions. (It is reference HCL to adapt, not a module to `source`.)
2. Fill `project_id`, `name`, `location`, and (recommended) `secrets_kms_key` + `bulletins_topic`.
3. Run `terraform fmt`, `terraform init`, `terraform validate`, then `terraform plan` against the target project. Some private-cluster networking requirements only surface at plan/apply.

## Gotchas (these are the ones people get wrong)

- `insecure_kubelet_readonly_port_enabled` is a **string** `"FALSE"`/`"TRUE"`, not a boolean.
- Autopilot ≠ skip everything: nodes default to the Compute Engine SA unless you set a custom one in **both** `node_config` and `cluster_autoscaling.auto_provisioning_defaults`.
- Private nodes have **no outbound internet** — add Cloud NAT + Private Google Access or image pulls fail.
- DNS endpoint `allow_external_traffic = false` makes the control plane **unreachable from a laptop** (in-Google-Cloud only). Set `true` if the user needs remote `kubectl` without a VPN.
- Binary Authorization's default policy is **allow-all** until you author one.
- Pin your `google` provider version; GKE adds and renames fields over time.

## Full write-up

See the companion article (link in the repo `README.md`) for the reasoning behind each control.
