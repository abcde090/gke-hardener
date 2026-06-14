variable "project_id" {
  type        = string
  description = "Project that hosts the cluster."
}

variable "name" {
  type        = string
  description = "Cluster name."
  default     = "hardened-autopilot"
}

variable "location" {
  type        = string
  description = "Region for the Autopilot cluster."
  default     = "australia-southeast1"
}

variable "network" {
  type        = string
  description = "VPC network self-link or name."
  default     = "default"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork self-link or name."
  default     = "default"
}

variable "release_channel" {
  type        = string
  description = "GKE release channel (RAPID, REGULAR, STABLE)."
  default     = "REGULAR"
}

variable "dns_allow_external_traffic" {
  type        = bool
  description = <<-EOT
    Control-plane DNS-endpoint reachability. No default — choose deliberately:
      true  = reachable from anywhere that can reach Google APIs (remote kubectl from a
              laptop/CI, IAM-gated, no VPN needed).
      false = reachable ONLY from within Google Cloud (your VPC, Cloud Shell, a bastion/GCE
              VM, or on-prem via Cloud VPN/Interconnect). Not reachable from a laptop directly.
    IAM authenticates every request either way; pair with VPC Service Controls for defence in depth.
  EOT
}

variable "deletion_protection" {
  type        = bool
  description = "Block accidental cluster deletion."
  default     = true
}

variable "secrets_kms_key" {
  type        = string
  description = "Cloud KMS key (full resource ID) for application-layer Secret encryption. null to skip."
  default     = null
}

variable "bulletins_topic" {
  type        = string
  description = "Pub/Sub topic (full resource ID) for security-bulletin notifications. null to skip."
  default     = null
}
