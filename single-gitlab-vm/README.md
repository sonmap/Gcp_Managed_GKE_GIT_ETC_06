# Single GitLab CE VM 빠른 테스트

GitLab을 GKE에 설치하지 않고 `prj-b-cicd-local-236d`의 Compute Engine VM 1대에 설치하는 테스트 환경입니다.

## 생성 자원

| 자원 | 기본값 |
|---|---|
| 프로젝트 | `prj-b-cicd-local-236d` |
| 리전/존 | `asia-northeast3` / `asia-northeast3-a` |
| VPC | `projects/pjt-d-shared-base/global/networks/vpc-d-shared-base` |
| Subnet | `subnet-common-cicd` (`172.31.20.0/24`) |
| GitLab VM | `gitlab-single-01`, `e2-standard-4` |
| 내부 IP | `172.31.20.20` |
| Boot Disk | Ubuntu 22.04 LTS, 50 GB |
| Data Disk | Balanced PD, 100 GB, `/var/opt/gitlab` |
| GitLab | Community Edition Linux package |
| PostgreSQL/Redis | GitLab Omnibus 내장 구성 |

이 구성은 다음 자원을 만들지 않습니다.

- GitLab용 GKE 클러스터
- Cloud SQL
- Memorystore Redis
- HTTPS/SSH Load Balancer
- 과제용 `pjt-c-admin` GKE Autopilot 변경

## 사전 조건

1. 실행 계정에 서비스 프로젝트 VM/Service Account 생성 권한이 있어야 합니다.
2. Shared VPC Subnet 사용 권한 `roles/compute.networkUser`가 필요합니다.
3. 방화벽을 생성하면 `pjt-d-shared-base`에 방화벽 생성 권한이 필요합니다.
4. 외부 IP를 사용하지 않는 기본 구성에서는 Cloud NAT 또는 사내 GitLab 패키지 미러가 필요합니다.
5. 테스트 PC가 `172.31.20.20`으로 라우팅 가능해야 합니다.

## 방법 1: Terraform

```bash
cd single-gitlab-vm/terraform
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

조직 정책에서 테스트용 외부 IP를 허용하고 Cloud NAT가 없다면 다음처럼 일시적으로 사용할 수 있습니다.

```bash
terraform apply -var='enable_public_ip=true'
```

## 방법 2: gcloud

```bash
cd single-gitlab-vm/gcloud
chmod +x deploy.sh delete.sh startup.sh

CREATE_FIREWALL=true ./deploy.sh
```

Cloud NAT가 없고 외부 IP가 허용되는 테스트 프로젝트라면:

```bash
ENABLE_PUBLIC_IP=true CREATE_FIREWALL=true ./deploy.sh
```

## 설치 진행 확인

```bash
gcloud compute ssh gitlab-single-01 \
  --project=prj-b-cicd-local-236d \
  --zone=asia-northeast3-a \
  --internal-ip \
  --command='sudo tail -100 /var/log/gitlab-bootstrap.log'
```

GitLab 상태 확인:

```bash
gcloud compute ssh gitlab-single-01 \
  --project=prj-b-cicd-local-236d \
  --zone=asia-northeast3-a \
  --internal-ip \
  --command='sudo gitlab-ctl status'

curl -I http://172.31.20.20/-/health
```

초기 `root` 비밀번호 확인:

```bash
gcloud compute ssh gitlab-single-01 \
  --project=prj-b-cicd-local-236d \
  --zone=asia-northeast3-a \
  --internal-ip \
  --command='sudo cat /etc/gitlab/initial_root_password'
```

초기 비밀번호 파일은 GitLab 설치 후 일정 시간이 지나면 제거되므로 즉시 변경합니다.

## 삭제

Terraform:

```bash
terraform destroy
```

gcloud:

```bash
CONFIRM_DESTROY=yes ./delete.sh
```

## 운영 전환 시 추가할 항목

- Internal HTTPS LB `172.31.20.10:443`
- Internal TCP LB `172.31.20.11:22`
- 회사 인증서와 Private DNS
- GCS GitLab Backup
- VM Snapshot 정책
- Cloud Monitoring 알림
- 필요 시 Cloud SQL 및 Memorystore 분리

공식 문서:

- https://docs.gitlab.com/install/package/
- https://docs.gitlab.com/install/package/ubuntu/
- https://cloud.google.com/vpc/docs/shared-vpc

