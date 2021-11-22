variable "project_id" {
  description = "The ID of an existing GCP project to target"
  type        = string
}
variable "service_account_id" {
  description = "The ID to use for the new IAM service account and related resources"
  type        = string
  default     = "github-actions"
}
variable "project_role" {
  description = "The GCP project IAM role to assign to the new IAM service account controllable by GitHub Actions workflows of the specified GitHub repository"
  type        = string
  default     = "roles/owner"
}
variable "github_repository" {
  description = "A specific GitHub repository with GitHub Actions workflows"
  type        = string
}