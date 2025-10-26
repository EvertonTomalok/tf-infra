output "hello_function_url" {
  description = "The URL of the Hello World Cloud Function"
  value       = module.hello_function.function_url
}

output "hello_function_name" {
  description = "The name of the Hello World Cloud Function"
  value       = module.hello_function.function_name
}

output "api_function_url" {
  description = "The URL of the API handler Cloud Function"
  value       = module.api_function.function_url
}

output "api_function_name" {
  description = "The name of the API handler Cloud Function"
  value       = module.api_function.function_name
}

output "instructions" {
  description = "Instructions for using the deployed functions"
  value       = <<-EOT
    Hello World Function:
      URL: ${module.hello_function.function_url}
      Name: ${module.hello_function.function_name}
    
    API Handler Function:
      URL: ${module.api_function.function_url}
      Name: ${module.api_function.function_name}
    
    To test the Hello World function:
    curl ${module.hello_function.function_url}
    
    Note: Ensure your function archives are uploaded to the GCS bucket before deploying.
  EOT
}
