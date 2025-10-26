output "function_name" {
  description = "The name of the Cloud Function"
  value       = google_cloudfunctions_function.function.name
}

output "function_id" {
  description = "An identifier for the resource"
  value       = google_cloudfunctions_function.function.id
}

output "function_url" {
  description = "The URL of the Cloud Function"
  value       = google_cloudfunctions_function.function.https_trigger_url
}

output "function_service_account_email" {
  description = "The service account email for the function"
  value       = google_cloudfunctions_function.function.service_account_email
}

output "function_runtime" {
  description = "The runtime of the Cloud Function"
  value       = google_cloudfunctions_function.function.runtime
}

output "function_available_memory_mb" {
  description = "The amount of memory available to the function"
  value       = google_cloudfunctions_function.function.available_memory_mb
}
