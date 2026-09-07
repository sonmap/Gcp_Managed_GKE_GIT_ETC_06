#!/usr/bin/env bash
set -Eeuo pipefail

exec > >(tee -a /var/log/gitlab-bootstrap.log) 2>&1

export DEBIAN_FRONTEND=noninteractive
DEVICE="/dev/disk/by-id/google-gitlab-data"
MOUNT_POINT="/var/opt/gitlab"
METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes/gitlab-external-url"
GITLAB_EXTERNAL_URL=$(curl -fsS -H "Metadata-Flavor: Google" "$METADATA_URL")

for attempt in $(seq 1 30); do
  test -b "$DEVICE" && break
  sleep 2
done
test -b "$DEVICE"

if ! blkid "$DEVICE" >/dev/null 2>&1; then
  mkfs.ext4 -F "$DEVICE"
fi
mkdir -p "$MOUNT_POINT"
DISK_UUID=$(blkid -s UUID -o value "$DEVICE")
grep -q "$DISK_UUID" /etc/fstab || echo "UUID=$DISK_UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
mountpoint -q "$MOUNT_POINT" || mount "$MOUNT_POINT"

apt-get update
apt-get install -y curl ca-certificates openssh-server tzdata perl
curl -fsSL "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh" -o /tmp/gitlab-ce-repository.sh
bash /tmp/gitlab-ce-repository.sh
EXTERNAL_URL="$GITLAB_EXTERNAL_URL" apt-get install -y gitlab-ce

cat >> /etc/gitlab/gitlab.rb <<'GITLAB_CONFIG'
gitlab_rails['time_zone'] = 'Asia/Seoul'
gitlab_rails['backup_keep_time'] = 604800
letsencrypt['enable'] = false
GITLAB_CONFIG

gitlab-ctl reconfigure
gitlab-ctl status
curl --fail --retry 20 --retry-delay 10 http://127.0.0.1/-/health
touch /var/lib/gitlab-bootstrap-complete

