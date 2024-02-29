variable "state_bucket_name" {
  type = string
  description = "The Name of the TF remote state S3 Bucket"
  default = "hello-world-app-tf-state-bucket"
}