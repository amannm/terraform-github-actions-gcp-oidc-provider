variable "project_id" {
  description = "The ID of the target GCP project"
  type        = string
}
variable "project_role" {
  description = "The GCP project IAM role to assign to GitHub Actions workflows of the specified GitHub repository"
  type        = string
  default     = "roles/owner"
}
variable "github_repository" {
  description = "A GitHub repository with GitHub Actions workflows"
  type        = string
}