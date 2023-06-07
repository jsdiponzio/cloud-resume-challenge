terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">= 4.16.0"
    }
  }
}

provider "google" {
  project = "jess-cloud-resume-challenge"
  region = "us-east1"
  zone = "us-east1-b"
}

resource "google_storage_bucket" "static" {
  name = "diponzio-test-1"
  location = "US"
  storage_class = "STANDARD"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page = "404.html"
  }
}
