variable "project_id" {
  type        = string
  description = "Project that hosts the cluster."
}

variable "name" {
  type        = string
  description = "Cluster name."
  default     = "hardened"
}

variable "location" {
  type        = string
  description = "Region (recommended) or zone for the cluster."
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
  description = "GKE release channel (RAPID, REGULAR, STABLE) — enables node auto-upgrade."
  default     = "REGULAR"
}

variable "node_count" {
  type        = number
  description = "Nodes per zone in the primary node pool."
  default     = 1
}

variable "machine_type" {
  type        = string
  description = "Node machine type."
  default     = "e2-standard-4"
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
