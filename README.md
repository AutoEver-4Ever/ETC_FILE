# 🚀 AutoEver MSA 프로젝트 실행 가이드

이 가이드는 MSA(마이크로서비스 아키텍처)로 구성된 `_4EVER` 프로젝트의 개발 환경을 설정하고, 애플리케이션을 실행하는 전체 과정을 안내합니다.

---

## 📚 목차

1.  [프로젝트 아키텍처 개요](#-프로젝트-아키텍처-개요)
2.  [사전 준비: 개발 환경 설정](#-사전-준비-개발-환경-설정)
    - [공통 필수 프로그램](#-공통-필수-프로그램)
    - [컨테이너 환경 설정 (OS별 선택)](#-컨테이너-환경-설정-os별-선택)
      - [macOS 사용자](#macos-사용자)
      - [Windows 사용자](#windows-사용자)
      - [Linux 사용자](#linux-사용자)
3.  [프로젝트 초기 설정](#️-프로젝트-초기-설정)
    - [1단계: Git 리포지토리 클론](#1단계-git-리포지토리-클론)
    - [2단계: 환경 설정 파일 이동](#2단계-환경-설정-파일-이동)
    - [3단계: Gradle Wrapper 설정 (최초 1회)](#3단계-gradle-wrapper-설정-최초-1회)
4.  [주요 사용법 (Makefile 명령어)](#️-주요-사용법-makefile-명령어)
    - [개발 핵심 플로우](#-개발-핵심-플로우)
    - [전체 서비스 관리](#-전체-서비스-관리)
    - [개별 서비스 관리](#-개별-서비스-관리)
5.  [인프라스트럭처 관리](#-인프라스트럭처-관리)
    - [데이터베이스 (PostgreSQL)](#-데이터베이스-postgresql)
    - [메시지 큐 (Kafka)](#-메시지-큐-kafka)
    - [인메모리 저장소 (Redis)](#-인메모리-저장소-redis)
    - [모든 인프라 통합 관리](#-모든-인프라-통합-관리)
6.  [프로덕션(운영) 환경 관리](#-프로덕션운영-환경-관리)
7.  [문제 해결 가이드](#-문제-해결-가이드)

---

## 🏗️ 프로젝트 아키텍처 개요

본 프로젝트는 여러 개의 독립적인 마이크로서비스(`Gateway`, `Auth`, `Business` 등)가 모여 하나의 애플리케이션을 구성합니다. 각 서비스는 자체 데이터베이스를 가지며, 서비스 간 통신이나 이벤트 처리는 API Gateway와 Kafka 메시지 큐를 통해 이루어집니다.

모든 서비스와 인프라(DB, Kafka, Redis)는 Docker 컨테이너 환경에서 실행되어 개발 환경의 일관성을 유지합니다. `Makefile`은 이러한 복잡한 환경을 손쉽게 관리할 수 있도록 도와주는 명령어 모음입니다.


---

## 🛠️ 사전 준비: 개발 환경 설정

프로젝트를 실행하기 위해 아래 프로그램들을 먼저 설치해야 합니다.

### 💻 공통 필수 프로그램

-   **Git**: 코드 버전 관리를 위해 필요합니다. [다운로드](https://git-scm.com/)

### 🐳 컨테이너 환경 설정 (OS별 선택)

Docker 컨테이너를 실행하기 위한 환경을 구성합니다. 사용하시는 운영체제에 맞춰 **하나만** 선택하여 진행하세요.

#### **macOS 사용자**

Homebrew를 이용한 설치를 권장합니다. 터미널을 열고 아래 명령어를 순서대로 입력하세요.

```bash
# Homebrew가 없다면 먼저 설치
/bin/bash -c "$(curl -fsSL [https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh))"

# Docker, Docker Compose, Colima 설치
brew install docker docker-compose colima

# Colima VM 시작 (최초 1회, Docker Desktop 대체)
colima start --cpu 4 --memory 8
```
> **💡 정보:** `Colima`는 Docker Desktop의 유료 정책을 피하고, 더 가벼운 가상 머신 환경을 제공하는 오픈소스입니다. `colima start` 후 터미널에서 `docker` 명령어를 사용할 수 있습니다.

#### **Windows 사용자**

Docker Desktop과 WSL2(Windows Subsystem for Linux 2)를 사용하는 것이 가장 안정적입니다.

1.  **WSL2 설치 및 설정**: [MS 공식 가이드](https://learn.microsoft.com/ko-kr/windows/wsl/install)를 따라 WSL2를 설치합니다. 터미널에서 `wsl --install` 명령어로 간단히 설치할 수 있습니다.
2.  **Docker Desktop 설치**: [Docker 공식 홈페이지](https://www.docker.com/products/docker-desktop/)에서 Docker Desktop for Windows를 다운로드하여 설치합니다. 설치 과정에서 "Use WSL 2 instead of Hyper-V" 옵션을 반드시 체크하세요.

#### **Linux 사용자**

`apt` 패키지 매니저(Ubuntu/Debian 기준)를 사용하여 Docker Engine과 Compose 플러그인을 설치합니다.

```bash
# Docker 공식 GPG 키 추가 및 저장소 설정
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker Engine 및 Compose 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

## ⚙️ 프로젝트 초기 설정

개발 환경 구성이 완료되었다면, 아래 순서에 따라 프로젝트 코드를 준비합니다.

### 1단계: Git 리포지토리 클론

개발에 필요한 모든 리포지토리를 작업할 폴더(workspace) 안에 `git clone` 받습니다.

```bash
# <저장소_URL>은 실제 Git 리포지토리 주소로 변경해주세요.
git clone <_4EVER_BE_ALARM_저장소_URL>
git clone <_4EVER_BE_AUTH_저장소_URL>
# ... (나머지 서비스 리포지토리 클론)
git clone <ETC_FILE_저장소_URL>
```

### 2단계: 환경 설정 파일 이동

`ETC_FILE` 리포지토리에 있는 Docker 및 빌드 관련 설정 파일들(`docker-compose.yml`, `Makefile` 등)을 **모든 프로젝트가 클론된 상위 폴더(workspace)로** 옮깁니다.

파일을 모두 옮긴 후, 비어있는 `ETC_FILE` 폴더는 삭제해도 됩니다.

```
# 최종 폴더 구조 예시
workspace/
├── _4EVER_BE_ALARM/
├── _4EVER_BE_AUTH/
├── ... (다른 서비스 폴더들)
├── docker-compose.yml  <-- 여기로 이동!
└── Makefile            <-- 여기로 이동!
```

### 3단계: Gradle Wrapper 설정 (최초 1회)

도커 빌드 안정성을 위해 각 서비스 프로젝트에 `gradle-wrapper.jar` 파일을 생성합니다. **프로젝트 설정 시 한 번만** 실행하면 됩니다.

프로젝트들의 최상위 폴더(workspace)에서 아래 명령어를 실행하세요.

```bash
for dir in _4EVER_BE_*; do                                                                               
  echo "Creating gradle-wrapper.jar for $dir"
  curl -L https://github.com/gradle/gradle/raw/v8.14.3/gradle/wrapper/gradle-wrapper.jar -o "$dir/gradle/wrapper/gradle-wrapper.jar"
done
echo "Gradle Wrapper 설정 완료!"
```

---

## ▶️ 주요 사용법 (Makefile 명령어)

모든 설정이 완료되었습니다! 이제 `Makefile`이 있는 최상위 폴더에서 간단한 명령어로 프로젝트 전체를 관리할 수 있습니다.

### ✅ 간단 사용법
1. 프로젝트 실행 (개발 모드)
모든 서비스의 도커 이미지를 빌드하고 컨테이너를 실행합니다.

```bash

make dev

```

2. 프로젝트 종료
실행 중인 모든 서비스 컨테이너를 중지하고 깨끗하게 제거합니다.
```bash

make down

```
3. 서비스 상태 확인
현재 실행 중인 컨테이너들의 상태를 확인합니다.
```bash

make status

```

### 🌟 개발 핵심 플로우

가장 자주 사용하게 될 명령어입니다.

-   **`make dev`**: **개발 환경 전체 시작**
    -   기존 Kafka 볼륨을 초기화하고, 모든 서비스 이미지를 새로 빌드한 후, 전체 컨테이너를 백그라운드에서 실행합니다. 마지막으로 서비스 상태를 보여줍니다.
-   **`make down`**: **개발 환경 전체 종료**
    -   실행 중인 모든 서비스 컨테이너를 중지하고 제거합니다. Kafka 데이터 볼륨도 함께 삭제하여 다음 실행 시 깨끗한 상태에서 시작하도록 합니다.

### 🔄 리포지토리 최신화 (MSA 전체)

여러 마이크로서비스 리포지토리를 한 번에 최신 상태로 업데이트합니다. 현재 폴더에서 `_4EVER_BE_*` 패턴에 매칭되는 디렉터리들을 자동으로 탐색합니다.

```bash
# 안전한 병합 방식(merge)로 최신화 (기본)
make update-repos

# 직접 실행 (옵션 커스터마이즈 가능)
./scripts/update-repos.sh -r . -p "_4EVER_BE_*" --stash --no-rebase

# 예시: develop 브랜치 강제 동기화 (주의: 로컬 변경사항 폐기)
./scripts/update-repos.sh --branch develop --force
```

옵션 요약:
- `--branch <name>`: 특정 브랜치를 명시 (미지정 시 `origin/HEAD` 추적 브랜치 사용)
- `--stash`/`--pop-stash`: 업데이트 전 변경사항 임시 저장(필요시 복원)
- `--no-rebase`: 병합(merge)로 pull, 기본은 rebase
- `--force`: 원격 브랜치 상태로 강제 초기화(로컬 변경사항 폐기)
- `--submodules`: 서브모듈까지 재귀적으로 최신화

### 📋 전체 서비스 관리

-   **`make status`**: 실행 중인 모든 서비스와 데이터베이스의 상태를 확인합니다.
-   **`make logs`**: 모든 서비스의 로그를 터미널에 실시간으로 출력합니다. (`Ctrl + C`로 종료)
-   **`make restart`**: 모든 서비스를 재시작합니다.
-   **`make clean`**: 사용하지 않는 도커 이미지, 네트워크, 볼륨 등 모든 리소스를 정리하여 디스크 공간을 확보합니다.

### 🔧 개별 서비스 관리

전체가 아닌 특정 서비스만 제어하고 싶을 때 사용합니다. `service` 부분에 `gateway`, `auth` 등 원하는 서비스 이름을 넣으세요.

-   **`make up-<service>`**: 특정 서비스만 시작합니다. (예: `make up-gateway`)
-   **`make logs-<service>`**: 특정 서비스의 로그만 실시간으로 봅니다. (예: `make logs-auth`)
-   **`make restart-<service>`**: 특정 서비스를 재시작합니다.

---

## 🔗 인프라스트럭처 관리

데이터베이스, Kafka, Redis 등 개별 인프라를 직접 관리할 때 사용하는 명령어입니다.

### 🗄️ 데이터베이스 (PostgreSQL)

-   **`make db-up` / `db-down`**: 모든 DB 컨테이너를 시작/중지합니다.
-   **`make db-status`**: 모든 DB의 상태와 외부 접속 정보를 확인합니다.
-   **`make db-logs`**: 모든 DB의 로그를 확인합니다.
-   **`make db-reset`**: **주의!** 모든 DB 컨테이너와 데이터를 영구적으로 삭제하고 다시 생성합니다.
-   **`make db-connect-<service>`**: 특정 서비스의 DB에 `psql` 클라이언트로 직접 접속합니다. (예: `make db-connect-auth`)

###  kafka 메시지 큐 (Kafka)

-   **`make kafka-up` / `kafka-down`**: Zookeeper와 Kafka를 함께 시작/중지합니다.
-   **`make kafka-logs`**: Kafka 컨테이너의 로그를 확인합니다.
-   **`make kafka-topics`**: 현재 생성된 토픽 목록을 조회합니다.
-   **`make kafka-create-topic TOPIC=<이름>`**: 새로운 토픽을 생성합니다. (예: `make kafka-create-topic TOPIC=my-topic`)

### 🔴 인메모리 저장소 (Redis)

-   **`make redis-up` / `redis-down`**: Redis 컨테이너를 시작/중지합니다.
-   **`make redis-cli`**: Redis CLI에 접속하여 직접 명령어를 입력할 수 있습니다.
-   **`make redis-monitor`**: Redis 서버에서 처리되는 모든 명령을 실시간으로 모니터링합니다.

### 🏗️ 모든 인프라 통합 관리

-   **`make infra-up` / `infra-down`**: 모든 데이터베이스, Kafka, Redis를 한 번에 시작/중지합니다.
-   **`make infra-status`**: 모든 인프라 서비스의 상태와 접속 정보를 종합하여 보여줍니다.

---

## 🏭 프로덕션(운영) 환경 관리

**주의:** 이 명령어들은 `docker-compose-prod.yml` 파일을 사용하며, 운영 환경 배포를 위한 것입니다.

-   **`make deploy-prod`**: 운영용 이미지를 빌드하고 모든 서비스를 배포/시작합니다.
-   **`make down-prod`**: 운영 환경의 모든 서비스를 중지합니다.
-   **`make status-prod`**: 운영 서비스의 상태와 엔드포인트 정보를 확인합니다.
-   **`make logs-prod`**: 운영 환경의 전체 서비스 로그를 확인합니다.

---

## 💡 문제 해결 가이드

-   **`make` 명령어 실행 시 `command not found` 오류가 발생하나요?**
    -   Windows: `make`를 사용하려면 `choco install make` 또는 WSL2 환경에서 실행해야 합니다.
    -   macOS/Linux: `make`가 기본적으로 설치되어 있으나, 없다면 `xcode-select --install` (macOS) 또는 `sudo apt-get install build-essential` (Linux)로 설치할 수 있습니다.
-   **`docker` 명령어 실행 시 `cannot connect to the Docker daemon` 오류가 발생하나요?**
    -   Docker Desktop이 실행 중인지 확인하세요.
    -   Colima 사용자는 터미널에서 `colima status`를 입력하여 VM이 실행 중인지 확인하고, 아니라면 `colima start`를 실행하세요.
-   **포트 충돌(Port is already allocated) 오류가 발생하나요?**
    -   `docker-compose.yml`에 정의된 포트(8080-8086, 9092, 6379 등)를 다른 애플리케이션이 사용 중일 수 있습니다. 해당 프로세스를 종료하거나 `docker-compose.yml` 파일의 포트 번호를 수정하세요.
