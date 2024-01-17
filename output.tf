# Vemos el output para verificar si el sito en el bucket es funcional.
output "website_url" {
  description = "URL of the website"
  value       = aws_s3_bucket_website_configuration.bucket_proyecto_1.website_endpoint
}