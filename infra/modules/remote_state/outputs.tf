output "state_bucket_name" {
  value = aws_s3_bucket.state_bucket.bucket
  description = "Terraform S3 remote state bucket name"
}