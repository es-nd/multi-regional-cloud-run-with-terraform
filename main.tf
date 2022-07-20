locals {
  cloud_run_deploy_regions = [var.tokyo_region, var.osaka_region]
}

# Clood Run
resource "google_cloud_run_service" "api" {
  for_each = toset(local.cloud_run_deploy_regions)
  name     = "api"
  location = each.key

  template {
    spec {
      containers {
        image = var.cloud_run_image
        ports {
          name           = "http1"
          container_port = 8080
        }
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress"      = "internal-and-cloud-load-balancing"
      "run.googleapis.com/launch-stage" = "BETA"
    }
  }

  autogenerate_revision_name = true

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "api_member" {
  for_each = toset(local.cloud_run_deploy_regions)
  location = google_cloud_run_service.api[each.key].location
  project  = google_cloud_run_service.api[each.key].project
  service  = google_cloud_run_service.api[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Load Balancing
resource "google_compute_global_address" "api" {
  project = var.gcp_project_id
  name    = "${var.api_name}-ip"
}

resource "google_compute_region_network_endpoint_group" "api" {
  for_each              = toset(local.cloud_run_deploy_regions)
  name                  = "${var.api_name}-region-network-endpoint-group-${each.key}"
  network_endpoint_type = "SERVERLESS"
  region                = each.key
  cloud_run {
    service = google_cloud_run_service.api[each.key].name
  }
}

resource "google_compute_backend_service" "api" {
  name     = "${var.api_name}-backend-service"
  protocol = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.api[var.tokyo_region].self_link
  }
  backend {
    group = google_compute_region_network_endpoint_group.api[var.osaka_region].self_link
  }
}

resource "google_compute_url_map" "api" {
  project         = var.gcp_project_id
  name            = "${var.api_name}-url-map"
  default_service = google_compute_backend_service.api.self_link
}

resource "google_compute_target_http_proxy" "api" {
  project = var.gcp_project_id
  name    = "${var.api_name}-target-http-proxy"
  url_map = google_compute_url_map.api.self_link
}

resource "google_compute_global_forwarding_rule" "api" {
  project    = var.gcp_project_id
  name       = "${var.api_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.api.self_link
  port_range = "80"
  ip_address = google_compute_global_address.api.address
}
