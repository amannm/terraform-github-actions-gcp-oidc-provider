terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google"
      version = ">= 3.47.0"
    }
  }
}

locals {
  github_actions_provider_hostname         = "token.actions.githubusercontent.com"
  github_actions_identity_pool_id          = "github-actions-id-pool"
  github_actions_identity_pool_provider_id = "github-actions-id-pool-provider"
  github_actions_service_account_id        = "github-actions-service-account"
}

// there is a service account with the specified project role
resource "google_service_account" "service-account" {
  account_id = local.github_actions_service_account_id
}
resource "google_project_iam_member" "service-account-project-role" {
  project = var.project_id
  role    = var.project_role
  member  = ["serviceAccount:${google_service_account.service-account.name}"]
}

// there is a pool of identities allowed to assume control of that service account
resource "google_iam_workload_identity_pool" "identity-pool" {
  provider                  = google-beta
  workload_identity_pool_id = local.github_actions_identity_pool_id
}
resource "google_service_account_iam_binding" "identity-pool-service-account-role" {
  service_account_id = google_service_account.service-account.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.identity-pool.workload_identity_pool_id}/*"
  ]
}

// there are OIDC identities issued by GitHub Actions that will be added to that pool if they represent the specified GitHub repository
resource "google_iam_workload_identity_pool_provider" "identity-pool-provider" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.identity-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = local.github_actions_identity_pool_provider_id
  oidc {
    issuer_uri = "https://${local.github_actions_provider_hostname}"
  }
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  attribute_condition = "google.subject.startsWith(\"repo:${var.github_repository}:\")"
}