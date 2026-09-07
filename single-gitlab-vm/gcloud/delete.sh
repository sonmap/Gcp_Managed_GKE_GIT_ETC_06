#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ID="${PROJECT_ID:-prj-b-cicd-local-236d}"
NETWORK_PROJECT_ID="${NETWORK_PROJECT_ID:-pjt-d-shared-base}"
REGION="${REGION:-asia-northeast3}"
ZONE="${ZONE:-asia-northeast3-a}"
INSTANCE_NAME="${INSTANCE_NAME:-gitlab-single-01}"
ADDRESS_NAME="${ADDRESS_NAME:-ip-gitlab-single-01}"
DATA_DISK_NAME="${DATA_DISK_NAME:-disk-gitlab-data-01}"
FIREWALL_NAME="${FIREWALL_NAME:-fw-gitlab-single-allow-corp}"
DELETE_FIREWALL="${DELETE_FIREWALL:-false}"

if [[ "${CONFIRM_DESTROY:-no}" != "yes" ]]; then
  echo "Refusing deletion. Run with CONFIRM_DESTROY=yes."
  exit 2
fi

gcloud compute instances delete "$INSTANCE_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" --quiet || true

gcloud compute disks delete "$DATA_DISK_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" --quiet || true

gcloud compute addresses delete "$ADDRESS_NAME" \
  --project="$PROJECT_ID" --region="$REGION" --quiet || true

if [[ "$DELETE_FIREWALL" == "true" ]]; then
  gcloud compute firewall-rules delete "$FIREWALL_NAME" \
    --project="$NETWORK_PROJECT_ID" --quiet || true
fi

echo "Single GitLab test resources deleted."

