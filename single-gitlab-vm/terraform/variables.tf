variable "project_id" {
  description = "GitLab VM을 생성할 서비스 프로젝트"
  type        = string
  default     = "prj-b-cicd-local-236d"
}

variable "network_project_id" {
  description = "vpc-d-shared-base가 위치한 Shared VPC 호스트 프로젝트"
  type        = string
  default     = "pjt-d-shared-base"
}

variable "network_name" {
  description = "Shared VPC 이름"
  type        = string
  default     = "vpc-d-shared-base"
}

variable "subnet_name" {
  description = "GitLab VM이 사용하는 Subnet"
  type        = string
  default     = "subnet-common-cicd"
}

variable "region" {
  type    = string
  default = "asia-northeast3"
}

variable "zone" {
  type    = string
  default = "asia-northeast3-a"
}

variable "instance_name" {
  type    = string
  default = "gitlab-single-01"
}

variable "machine_type" {
  description = "소규모 테스트 시작 사양"
  type        = string
  default     = "e2-standard-4"
}

variable "internal_ip" {
  type    = string
  default = "172.31.20.20"
}

variable "gitlab_external_url" {
  description = "LB 적용 전 테스트 URL. 운영 전환 시 회사 FQDN으로 변경"
  type        = string
  default     = "http://172.31.20.20"
}

variable "boot_disk_size_gb" {
  type    = number
  default = 50
}

variable "data_disk_size_gb" {
  type    = number
  default = 100
}

variable "enable_public_ip" {
  description = "Cloud NAT가 없는 임시 테스트에서만 true 사용"
  type        = bool
  default     = false
}

variable "create_firewall_rule" {
  description = "Shared VPC 호스트 프로젝트에 테스트 Ingress 룰 생성"
  type        = bool
  default     = false
}

variable "source_ranges" {
  description = "GitLab HTTP/SSH 접속을 허용할 사내 CIDR"
  type        = list(string)
  default = [
    "172.28.107.0/24",
    "172.28.108.0/22",
    "172.28.112.0/20",
    "172.28.160.0/20",
    "172.28.176.0/22",
    "172.28.180.0/23",
    "172.28.184.0/22",
    "172.28.188.0/24"
  ]
}

variable "labels" {
  type = map(string)
  default = {
    environment = "test"
    service     = "gitlab"
    managed_by  = "terraform"
  }
}

