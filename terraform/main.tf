terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">= 4.16.0"
    }
  }
}

provider "google" {
  project = jess-cloud-resume-challenge
  region = "us-east1"
  zone = "us-east1-b"
  credentials = file(/jess-cloud-resume-challenge-service-account.json)
}