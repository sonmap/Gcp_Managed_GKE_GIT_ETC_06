#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ID="${PROJECT_ID:-prj-b-cicd-local-236d}"
NETWORK_PROJECT_ID="${NETWORK_PROJECT_ID:-pjt-d-shared-base}"
NETWORK_NAME="${NETWORK_NAME:-vpc-d-shared-base}"
SUBNET_NAME="${SUBNET_NAME:-subnet-common-cicd}"
REGION="${REGION:-asia-northeast3}"
ZONE="${ZONE:-asia-northeast3-a}"
INSTANCE_NAME="${INSTANCE_NAME:-gitlab-single-01}"
ADDRESS_NAME="${ADDRESS_NAME:-ip-gitlab-single-01}"
DATA_DISK_NAME="${DATA_DISK_NAME:-disk-gitlab-data-01}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-sa-gitlab-single}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-4}"
INTERNAL_IP="${INTERNAL_IP:-172.31.20.20}"
GITLAB_EXTERNAL_URL="${GITLAB_EXTERNAL_URL:-http://172.31.20.20}"
ENABLE_PUBLIC_IP="${ENABLE_PUBLIC_IP:-false}"
CREATE_FIREWALL="${CREATE_FIREWALL:-false}"
FIREWALL_NAME="${FIREWALL_NAME:-fw-gitlab-single-allow-corp}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SA_EMAIL="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
SUBNET_URI="projects/$NETWORK_PROJECT_ID/regions/$REGION/subnetworks/$SUBNET_NAME"

SOURCE_RANGES="${SOURCE_RANGES:-172.28.107.0/24,172.28.108.0/22,172.28.112.0/20,172.28.160.0/20,172.28.176.0/22,172.28.180.0/23,172.28.184.0/22,172.28.188.0/24}"

echo "Enabling Compute Engine API in $PROJECT_ID"
gcloud services enable compute.googleapis.com --project="$PROJECT_ID"

if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
    --project="$PROJECT_ID" \
    --display-name="Single GitLab VM"
fi

for role in roles/logging.logWriter roles/monitoring.metricWriter; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role" \
    --condition=None \
    --quiet >/dev/null
done

if ! gcloud compute addresses describe "$ADDRESS_NAME" --project="$PROJECT_ID" --region="$REGION" >/dev/null 2>&1; then
  gcloud compute addresses create "$ADDRESS_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --subnet="$SUBNET_URI" \
    --addresses="$INTERNAL_IP"
fi

if ! gcloud compute disks describe "$DATA_DISK_NAME" --project="$PROJECT_ID" --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute disks create "$DATA_DISK_NAME" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --type=pd-balanced \
    --size=100GB
fi

if [[ "$CREATE_FIREWALL" == "true" ]] && ! gcloud compute firewall-rules describe "$FIREWALL_NAME" --project="$NETWORK_PROJECT_ID" >/dev/null 2>&1; then
  gcloud compute firewall-rules create "$FIREWALL_NAME" \
    --project="$NETWORK_PROJECT_ID" \
    --network="$NETWORK_NAME" \
    --direction=INGRESS \
    --priority=900 \
    --action=ALLOW \
    --rules=tcp:22,tcp:80 \
    --source-ranges="$SOURCE_RANGES" \
    --target-tags=gitlab-single-vm \
    --enable-logging
fi

PUBLIC_IP_ARGS=(--no-address)
if [[ "$ENABLE_PUBLIC_IP" == "true" ]]; then
  PUBLIC_IP_ARGS=()
fi

gcloud compute instances create "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --subnet="$SUBNET_URI" \
  --private-network-ip="$INTERNAL_IP" \
  "${PUBLIC_IP_ARGS[@]}" \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-type=pd-balanced \
  --boot-disk-size=50GB \
  --disk="name=$DATA_DISK_NAME,device-name=gitlab-data,mode=rw,boot=no,auto-delete=no" \
  --service-account="$SA_EMAIL" \
  --scopes=cloud-platform \
  --tags=gitlab-single-vm \
  --labels=environment=test,service=gitlab,managed_by=gcloud \
  --metadata="enable-oslogin=TRUE,gitlab-external-url=$GITLAB_EXTERNAL_URL" \
  --metadata-from-file="startup-script=$SCRIPT_DIR/startup.sh"

echo "GitLab VM creation requested."
echo "URL: $GITLAB_EXTERNAL_URL"
echo "Bootstrap log: gcloud compute ssh $INSTANCE_NAME --project=$PROJECT_ID --zone=$ZONE --internal-ip --command='sudo tail -100 /var/log/gitlab-bootstrap.log'"

