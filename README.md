# GCP Managed GKE / GitLab Test Environments

GCP 테스트 인프라를 빠르게 검증하기 위한 예제 저장소입니다.

- `single-gitlab-vm/`: GitLab Community Edition을 Compute Engine VM 1대에 설치
- 과제용 GKE Autopilot 환경은 GitLab VM 구성과 독립적으로 유지

> 테스트 코드는 기본적으로 내부 IP만 사용합니다. 설치 패키지 다운로드를 위해 Cloud NAT 또는 사내 패키지 미러가 필요합니다.

