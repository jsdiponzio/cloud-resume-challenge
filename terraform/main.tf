terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.16.0"
    }
  }
}

provider "google" {
  project = "jess-cloud-resume-challenge"
  region  = "us-east1"
  zone    = "us-east1-b"
}

#create bucket
resource "google_storage_bucket" "website" {
  name                        = "jsdiponzio.com"
  location                    = "US"
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

data "archive_file" "zipped_code" {
  type        = "zip"
  output_path = "${path.module}/../terraform-zipped/back-end.zip"

  source {
    content  = templatefile("../back-end/main.py", {})
    filename = "main.py"
  }

  source {
    content  = templatefile("../back-end/requirements.txt", {})
    filename = "requirements.txt"
  }
}

#add bucket objects
resource "google_storage_bucket_object" "backend_code" {
  name         = "backend.zip"
  source       = data.archive_file.zipped_code.output_path
  content_type = "application/zip"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "index_html" {
  name         = "index.html"
  source       = "../front-end/index.html"
  content_type = "text/html"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "error_html" {
  name         = "404.html"
  source       = "../front-end/404.html"
  content_type = "text/html"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "index_js" {
  name         = "index.js"
  source       = "../front-end/index.js"
  content_type = "text/javascript"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "style_css" {
  name         = "style.css"
  source       = "../front-end/style.css"
  content_type = "text/css"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "assets" {
  name    = "assets/" # folder name should end with '/'
  content = " "
  bucket  = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "email_icon" {
  name         = "assets/email.png"
  source       = "../front-end/assets/email.png"
  content_type = "image/png"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "github_logo" {
  name         = "assets/github-logo.png"
  source       = "../front-end/assets/github-logo.png"
  content_type = "image/png"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "linkedin_logo" {
  name         = "assets/linkedin-logo.png"
  source       = "../front-end/assets/linkedin-logo.png"
  content_type = "image/png"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "location_icon" {
  name         = "assets/location.png"
  source       = "../front-end/assets/location.png"
  content_type = "image/png"
  bucket       = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "phone_icon" {
  name         = "assets/phone.png"
  source       = "../front-end/assets/phone.png"
  content_type = "image/png"
  bucket       = google_storage_bucket.website.name
}

#make public
resource "google_storage_bucket_iam_binding" "website_iam" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

#reserve ip
resource "google_compute_global_address" "default" {
  name = "jsdiponzio-ip"
}

#DNS
resource "google_dns_managed_zone" "dns_zone" {
  name     = "jsdiponzio"
  dns_name = "jsdiponzio.com."
  dnssec_config {
    state = "on"
  }
}

#add ip to dns
resource "google_dns_record_set" "website" {
  name         = google_dns_managed_zone.dns_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.default.address]
}

#lb backend bucket
resource "google_compute_backend_bucket" "website_backend" {
  name        = "jsdiponzio-backend"
  description = "Backend bucket"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

#ssl cert
resource "google_compute_managed_ssl_certificate" "website" {
  name = "jsdiponzio-ssl"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

#http url map
resource "google_compute_url_map" "http_map" {
  name        = "http-redirect"
  description = "Website URL map"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

#HTTP target proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-redirect-proxy"
  url_map = google_compute_url_map.http_map.self_link
}

#http forwarding rule
resource "google_compute_global_forwarding_rule" "http_fr" {
  name        = "http-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_http_proxy.http_proxy.self_link
  ip_address  = google_compute_global_address.default.address
}

#https url map
resource "google_compute_url_map" "https_map" {
  name            = "https-lb"
  description     = "Website URL map"
  default_service = google_compute_backend_bucket.website_backend.self_link
}

#https target proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "https-proxy"
  url_map          = google_compute_url_map.https_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

#https forwarding rule
resource "google_compute_global_forwarding_rule" "https_fr" {
  name                  = "https-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  ip_protocol           = "TCP"
  target                = google_compute_target_https_proxy.https_proxy.self_link
  ip_address            = google_compute_global_address.default.address
}

#firestore database
resource "google_project_service" "firestore" {
  service = "firestore.googleapis.com"
}

#add collection & document
resource "google_firestore_document" "visitors" {
  collection  = "site-views"
  document_id = "visitors"
  fields      = "{\"VisitorCount\":{\"integerValue\":1}}"

  lifecycle {
    ignore_changes = all
  }
}

#api
resource "google_cloudfunctions_function" "increment_function" {
  name        = "increment-fetch"
  description = "increments vistor count by 1"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.website.name
  source_archive_object = google_storage_bucket_object.backend_code.name
  trigger_http          = true
  entry_point           = "increment_fetch"
}

#public invokation to function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  region         = "us-east1"
  cloud_function = google_cloudfunctions_function.increment_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

