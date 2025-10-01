# 🚀 프로젝트 초기 설정 및 실행 가이드

이 가이드는 `_4EVER` 프로젝트를 처음 설정하고 실행하는 전체 과정을 안내합니다.

---

## 📋 사전 준비

- [Git](https://git-scm.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

---

## ⚙️ 초기 설정 절차

### 1. Git 리포지토리 클론

먼저, 개발에 필요한 모든 프로젝트 리포지토리를 작업할 폴더(workspace) 안에 `git clone` 받습니다.

```bash
# <저장소_URL> 부분은 실제 Git 리포지토리 주소로 변경해주세요.
git clone <_4EVER_BE_ALARM_저장소_URL>
git clone <_4EVER_BE_AUTH_저장소_URL>
git clone <_4EVER_BE_BUSINESS_저장소_URL>
git clone <_4EVER_BE_CB_저장소_URL>
git clone <_4EVER_BE_GW_저장소_URL>
git clone <_4EVER_BE_PAYMENT_저장소_URL>
git clone <_4EVER_BE_SCM_저장소_URL>
git clone <ETC_FILE_저장소_URL>
```

### 2. 환경 설정 파일 이동

`ETC_FILE` 리포지토리에 있는 환경 설정 파일들(`docker-compose.yml`, `Makefile` 등)을 **모든 프로젝트가 클론된 상위 폴더(workspace)로** 옮깁니다.

파일을 모두 옮긴 후, 비어있는 `ETC_FILE` 폴더는 삭제해도 됩니다.

### 3. Gradle Wrapper 설정 (최초 1회)

도커 빌드 시 발생할 수 있는 오류를 방지하기 위해, 각 서비스 프로젝트에 `gradle-wrapper.jar` 파일을 생성하는 스크립트를 실행합니다. 이 작업은 **프로젝트 설정 시 한 번만** 하면 됩니다.

프로젝트들의 최상위 폴더(workspace)에서 아래 명령어를 실행하세요.

```bash
# 각 _4EVER_BE_* 프로젝트에 gradle-wrapper.jar 파일을 다운로드합니다.
for dir in _4EVER_BE_*; do
  if [ -d "$dir" ]; then
    echo "Creating gradle-wrapper.jar for $dir"
    # gradle/wrapper 폴더가 없을 경우를 대비하여 생성
    mkdir -p "$dir/gradle/wrapper"
    # 지정된 버전의 jar 파일 다운로드 (v8.7 부분은 프로젝트 gradle 버전에 맞게 수정)
    curl -L [https://github.com/gradle/gradle/raw/v8.7/gradle/wrapper/gradle-wrapper.jar](https://github.com/gradle/gradle/raw/v8.7/gradle/wrapper/gradle-wrapper.jar) -o "$dir/gradle/wrapper/gradle-wrapper.jar"
  fi
done

echo "Gradle Wrapper 설정 완료!"
```

---

## ▶️ 프로젝트 실행 및 종료

이제 `Makefile`에 정의된 명령어로 모든 서비스를 간편하게 관리할 수 있습니다. 명령어는 **반드시 `Makefile`이 있는 최상위 폴더(workspace)에서 실행**해야 합니다.

### ✅ 프로젝트 실행 (개발 모드)

모든 서비스의 도커 이미지를 빌드하고 컨테이너를 실행합니다.

```bash
make dev
```

### ⏹️ 프로젝트 종료

실행 중인 모든 서비스 컨테이너를 중지하고 깨끗하게 제거합니다.

```bash
make down
```

### 📊 서비스 상태 확인

현재 실행 중인 컨테이너들의 상태를 확인합니다.

```bash
make status
```

### 🪵 서비스 로그 확인

모든 서비스의 로그를 실시간으로 확인합니다. (`Ctrl + C`로 종료)

```bash
make logs

# 특정 서비스의 로그만 보려면
docker compose logs -f <service_name>
# 예: docker compose logs -f auth
```
