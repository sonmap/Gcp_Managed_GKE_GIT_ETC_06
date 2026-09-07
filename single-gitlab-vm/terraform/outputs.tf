output "gitlab_internal_ip" {
  value = google_compute_address.gitlab_internal.address
}

output "gitlab_url" {
  value = var.gitlab_external_url
}

output "ssh_command" {
  value = "gcloud compute ssh ${var.instance_name} --project=${var.project_id} --zone=${var.zone} --internal-ip"
}

output "bootstrap_log_command" {
  value = "gcloud compute ssh ${var.instance_name} --project=${var.project_id} --zone=${var.zone} --internal-ip --command='sudo tail -100 /var/log/gitlab-bootstrap.log'"
}

output "initial_password_command" {
  value     = "gcloud compute ssh ${var.instance_name} --project=${var.project_id} --zone=${var.zone} --internal-ip --command='sudo cat /etc/gitlab/initial_root_password'"
  sensitive = true
}

