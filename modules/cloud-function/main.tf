resource "google_cloudfunctions_function" "function" {
  name                  = var.function_name
  description           = var.description
  runtime               = var.runtime
  available_memory_mb   = var.available_memory_mb
  timeout               = var.timeout
  source_archive_bucket = var.source_archive_bucket
  source_archive_object = var.source_archive_object
  entry_point           = var.entry_point

  https_trigger_url = true

  # Optional environment variables
  environment_variables = var.environment_variables

  # Labels
  labels = var.labels

  # Service account
  service_account_email = var.service_account_email

  # Networking
  vpc_connector                 = var.vpc_connector_name
  vpc_connector_egress_settings = var.vpc_connector_egress_settings

  # Ingestion settings
  max_instances = var.max_instances
  min_instances = var.min_instances
}

# IAM entry for allUsers to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  count          = var.allow_unauthenticated_invocations ? 1 : 0
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
