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

#create bucket
resource "google_storage_bucket" "website" {
  name = "diponzio-test-1"
  location = "US"
  storage_class = "STANDARD"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page = "404.html"
  }
}

#test bucket items
resource "google_storage_bucket_object" "hello" {
  name = "hello_world"
  source = "email.png"
  content_type = "image/png"
  bucket = google_storage_bucket.website.name
}

#make public
resource "google_storage_default_object_access_control" "website_read" {
  bucket = google_storage_bucket.website.name
  role = "READER"
  entity = "allUsers"
}

#reserve ip
resource "google_compute_global_address" "default" {
  name = "diponzio-test-ip"
}

#DNS /// change to imported dns zone after test
resource "google_dns_managed_zone" "diponzio_tf_test" {
  name = "diponzio-tf-test"
  dns_name = "jsdiponzio.com."
  dnssec_config {
    state = "on"
  }
}

#add ip to dns
resource "google_dns_record_set" "website" {
  name = "test.${google_dns_managed_zone.diponzio_tf_test.dns_name}"
  type = "A"
  ttl = 300
  managed_zone = google_dns_managed_zone.diponzio_tf_test.name
  rrdatas = [google_compute_global_address.default.address]
}

#lb backend bucket
resource "google_compute_backend_bucket" "website_backend" {
  name = "diponzio-test-backend"
  description = "Backend bucket test"
  bucket_name = google_storage_bucket.website.name
  enable_cdn = true
}

#ssl cert
resource "google_compute_managed_ssl_certificate" "website" {
  name     = "jsdiponzio-ssl-test"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

#http url map
resource "google_compute_url_map" "http_map" {
  name = "test-http-lb"
  description = "Website URL map"
  default_url_redirect {
    https_redirect = true
    strip_query = true
  }
}

#https url map
resource "google_compute_url_map" "https_map" {
  name = "test-https-lb"
  description = "Website URL map"
  default_service = google_compute_backend_bucket.website_backend.self_link
}


 #HTTP target proxy
resource "google_compute_target_http_proxy" "test_proxy_http" {
  name = "test-http-lb-proxy"
  url_map = google_compute_url_map.http_map.name
}

#http forwarding rule
resource "google_compute_global_forwarding_rule" "test_fr_http" {
  name = "test-forwarding-rule-http"
  ip_protocol = "TCP"
  port_range = "80"
  target = google_compute_target_http_proxy.test_proxy_http.self_link
  ip_address = google_compute_global_address.default.address
}

#https target proxy
resource "google_compute_target_https_proxy" "test_proxy_https" {
  name = "test-https-lb-proxy"
  url_map = google_compute_url_map.https_map.name
  ssl_certificates = [google_compute_managed_ssl_certificate.website.name]
}

#https forwarding rule
resource "google_compute_global_forwarding_rule" "test_fr_https" {
  name = "test-forwarding-rule-https"
  load_balancing_scheme = "EXTERNAL"
  port_range = "443"
  ip_protocol = "TCP"
  target = google_compute_target_https_proxy.test_proxy_https.self_link
  ip_address = google_compute_global_address.default.address
}

#firestore database
resource "google_project_service" "firestore" {
  service = "firestore.googleapis.com"
}

resource "google_firestore_database" "database" {
  name        = "(default)"
  location_id = "us-east1"
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.firestore]
}

#add collection & document
resource "google_firestore_document" "visitors" {
  collection = "site-views"
  document_id = "visitors"
  fields = "{\"visitor-count\":{\"integerValue\":0}}"
}








