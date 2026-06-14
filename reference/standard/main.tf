###############################################################################
# Hardened GKE — Standard mode
# Secure-by-default cluster: identity-gated control plane, Workload Identity,
# Binary Authorization, Shielded nodes, least-privilege node SA, Dataplane V2,
# denied externalIPs, optional CMEK Secret encryption + security bulletins.
###############################################################################

locals {
  node_sa_roles = toset([
    "roles/container.defaultNodeServiceAccount", # minimum for GKE nodes (logging, monitoring, metadata)
    "roles/artifactregistry.reader",             # pull private images, read-only
  ])
}

# --- Least-privilege node service account (never the default Compute Engine SA) ---
resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = "${var.name}-nodes"
  display_name = "GKE nodes (least privilege) - ${var.name}"
}

resource "google_project_iam_member" "nodes" {
  for_each = local.node_sa_roles
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.nodes.email}"
}

# --- Cluster (control plane) ---
resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = var.name
  location = var.location

  network    = var.network
  subnetwork = var.subnetwork

  # Manage our own hardened node pool instead of the default one.
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = var.deletion_protection

  # Nodes auto-upgrade on a release channel.
  release_channel {
    channel = var.release_channel
  }

  # VPC-native; required for private nodes and Dataplane V2.
  ip_allocation_policy {}

  # Dataplane V2 (eBPF) — includes network policy enforcement.
  datapath_provider = "ADVANCED_DATAPATH"

  # 1 - Reach the control plane by identity, not IP.
  private_cluster_config {
    enable_private_nodes = true # nodes get no external IPs
  }
  control_plane_endpoints_config {
    dns_endpoint_config {
      # true = remote kubectl from anywhere (IAM-gated); false = reachable only from within Google Cloud.
      allow_external_traffic = var.dns_allow_external_traffic
    }
    ip_endpoints_config {
      enabled = false # no IP-based (public) API endpoint
    }
  }

  # 2 - Per-workload identity.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # 3 - Only trusted images run (default policy is allow-all; author your policy + attestors).
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # 4 - Minimal node & runtime surface (cluster-level pieces).
  enable_shielded_nodes = true
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  node_pool_defaults {
    node_config_defaults {
      insecure_kubelet_readonly_port_enabled = "FALSE" # string enum, not a bool
    }
  }
  service_external_ips_config {
    enabled = false
  }

  # 5 - Encrypt Secrets with your own KMS key (optional).
  dynamic "database_encryption" {
    for_each = var.secrets_kms_key == null ? [] : [var.secrets_kms_key]
    content {
      state    = "ENCRYPTED"
      key_name = database_encryption.value
    }
  }

  # 6 - Security-bulletin notifications (optional).
  dynamic "notification_config" {
    for_each = var.bulletins_topic == null ? [] : [var.bulletins_topic]
    content {
      pubsub {
        enabled = true
        topic   = notification_config.value
        filter {
          event_type = ["SECURITY_BULLETIN_EVENT"]
        }
      }
    }
  }
}

# --- Hardened primary node pool ---
resource "google_container_node_pool" "primary" {
  project    = var.project_id
  name       = "${var.name}-primary"
  cluster    = google_container_cluster.this.id
  location   = var.location
  node_count = var.node_count

  # Auto-repair + auto-upgrade.
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    image_type      = "COS_CONTAINERD" # Container-Optimized OS
    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # Shielded VM: Secure Boot + integrity monitoring.
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Required for Workload Identity.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
