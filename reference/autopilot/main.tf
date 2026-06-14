###############################################################################
# Hardened GKE — Autopilot mode
# Autopilot already enforces the node + runtime layers (no SSH, Shielded nodes,
# Workload Identity, COS + auto-upgrade, restricted-ish Pod admission, seccomp
# RuntimeDefault, externalIPs blocked). This module adds what Autopilot does
# NOT do for you: a least-privilege node SA, private networking, Binary
# Authorization, and optional CMEK Secret encryption + security bulletins.
###############################################################################

locals {
  node_sa_roles = toset([
    "roles/container.defaultNodeServiceAccount",
    "roles/artifactregistry.reader",
  ])
}

# --- Least-privilege node service account (Autopilot defaults to the Compute Engine SA) ---
resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = "${var.name}-nodes"
  display_name = "GKE Autopilot nodes (least privilege) - ${var.name}"
}

resource "google_project_iam_member" "nodes" {
  for_each = local.node_sa_roles
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = var.name
  location = var.location

  network    = var.network
  subnetwork = var.subnetwork

  enable_autopilot    = true
  deletion_protection = var.deletion_protection

  release_channel {
    channel = var.release_channel
  }

  # Custom least-privilege node SA. For Autopilot it must be set in BOTH places.
  node_config {
    service_account = google_service_account.nodes.email
  }
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.nodes.email
    }
  }

  # 1 - Private networking is NOT automatic in Autopilot — turn it on explicitly.
  private_cluster_config {
    enable_private_nodes = true
  }
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = false
    }
    ip_endpoints_config {
      enabled = false
    }
  }

  # 3 - Binary Authorization is NOT automatic in Autopilot (default policy is allow-all).
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
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
