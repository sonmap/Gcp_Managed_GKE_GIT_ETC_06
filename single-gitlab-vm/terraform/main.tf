locals {
  network_self_link = "projects/${var.network_project_id}/global/networks/${var.network_name}"
  subnet_self_link  = "projects/${var.network_project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"
  network_tag       = "gitlab-single-vm"
}

resource "google_service_account" "gitlab" {
  project      = var.project_id
  account_id   = "sa-gitlab-single"
  display_name = "Single GitLab VM"
}

resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gitlab.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gitlab.email}"
}

resource "google_compute_address" "gitlab_internal" {
  project      = var.project_id
  name         = "ip-gitlab-single-01"
  region       = var.region
  address_type = "INTERNAL"
  address      = var.internal_ip
  subnetwork   = local.subnet_self_link
}

resource "google_compute_disk" "gitlab_data" {
  project = var.project_id
  name    = "disk-gitlab-data-01"
  type    = "pd-balanced"
  zone    = var.zone
  size    = var.data_disk_size_gb
  labels  = var.labels
}

resource "google_compute_instance" "gitlab" {
  project                   = var.project_id
  name                      = var.instance_name
  zone                      = var.zone
  machine_type              = var.machine_type
  allow_stopping_for_update = true
  deletion_protection       = false
  tags                      = [local.network_tag]
  labels                    = var.labels

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = google_compute_disk.gitlab_data.id
    device_name = "gitlab-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = local.subnet_self_link
    network_ip = google_compute_address.gitlab_internal.address

    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    gitlab_external_url = var.gitlab_external_url
  })

  service_account {
    email  = google_service_account.gitlab.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_iam_member.logging,
    google_project_iam_member.monitoring
  ]
}

resource "google_compute_firewall" "gitlab_ingress" {
  count   = var.create_firewall_rule ? 1 : 0
  project = var.network_project_id
  name    = "fw-gitlab-single-allow-corp"
  network = local.network_self_link

  direction     = "INGRESS"
  priority      = 900
  source_ranges = var.source_ranges
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

