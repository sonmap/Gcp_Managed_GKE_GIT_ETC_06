#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

bash -n "$ROOT_DIR/gcloud/deploy.sh"
bash -n "$ROOT_DIR/gcloud/delete.sh"
bash -n "$ROOT_DIR/gcloud/startup.sh"
bash -n "$ROOT_DIR/terraform/startup.sh.tftpl"

if command -v terraform >/dev/null 2>&1; then
  terraform -chdir="$ROOT_DIR/terraform" fmt -check -recursive
  terraform -chdir="$ROOT_DIR/terraform" init -backend=false
  terraform -chdir="$ROOT_DIR/terraform" validate
else
  echo "terraform not found; Bash syntax checks completed."
fi

