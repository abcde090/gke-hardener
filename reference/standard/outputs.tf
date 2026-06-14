output "cluster_name" {
  description = "Cluster name."
  value       = google_container_cluster.this.name
}

output "cluster_id" {
  description = "Fully-qualified cluster ID."
  value       = google_container_cluster.this.id
}

output "endpoint" {
  description = "Cluster API endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "node_service_account" {
  description = "Least-privilege node service account email."
  value       = google_service_account.nodes.email
}

output "location" {
  description = "Cluster location."
  value       = google_container_cluster.this.location
}
