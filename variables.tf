variable "app_name" {
  type    = string
  default = "sample"
}

variable "gcp_project_id" {
  type = string
}

variable "credentials_path" {
  type    = string
  default = "./credential.json"
}

variable "tokyo_region" {
  type    = string
  default = "asia-northeast1"
}

variable "osaka_region" {
  type    = string
  default = "asia-northeast2"
}

variable "api_name" {
  type    = string
  default = "api"
}

variable "cloud_run_image" {
  type    = string
  default = "gcr.io/cloudrun/hello"
}
