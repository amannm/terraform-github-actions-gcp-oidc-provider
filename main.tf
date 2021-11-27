terraform {
  required_providers {
    google-beta = {
      version = ">= 3.47.0"
    }
  }
}

locals {
  github_actions_provider_hostname         = "token.actions.githubusercontent.com"
  github_actions_identity_pool_id          = "${var.service_account_id}-id-pool"
  github_actions_identity_pool_provider_id = "${var.service_account_id}-id-pool-provider"
}

resource "google_project_service" "required_services" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sts.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

// there is a service account with the specified project role
resource "google_service_account" "service-account" {
  account_id = var.service_account_id
}
resource "google_project_iam_member" "service-account-project-role" {
  project = var.project_id
  role    = var.project_role
  member  = "serviceAccount:${google_service_account.service-account.email}"
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
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.identity-pool.name}/*"
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