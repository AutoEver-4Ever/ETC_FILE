.PHONY: help build up down restart logs clean status \
        rebuild-gateway rebuild-auth rebuild-alarm rebuild-business rebuild-payment rebuild-scm \
        up-gateway up-auth up-alarm up-business up-payment up-scm \
        logs-gateway logs-auth logs-alarm logs-business logs-payment logs-scm \
        restart-gateway restart-auth restart-alarm restart-business restart-payment restart-scm \
        prod-deploy-gateway prod-deploy-auth prod-deploy-alarm prod-deploy-business prod-deploy-payment prod-deploy-scm \
        prod-init prod-up prod-down prod-restart prod-logs prod-status \
        db-up db-down db-logs db-reset db-status db-backup \
        db-connect-auth db-connect-alarm db-connect-business db-connect-payment db-connect-scm \
        kafka-up kafka-down kafka-logs kafka-topics kafka-create-topic kafka-console \
        redis-up redis-down redis-logs redis-cli redis-monitor \
        infra-up infra-down infra-logs infra-status \
        clean-volumes clean-all health check-ports dev quick-start full-restart stats mem-total

# 기본 변수
COMPOSE_FILE := $(shell if [ -f docker-compose.yml ]; then echo "docker-compose.yml"; else echo "docker-compose.prod.yml"; fi)
# Auto-detect docker compose plugin vs standalone docker-compose
COMPOSE_DEV := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; \
                 elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; \
                 else echo "docker compose"; fi)
COMPOSE_PROD := $(COMPOSE_DEV) -f docker-compose.prod.yml
SERVICES = gateway auth alarm business payment scm

# 도움말 (기본 명령어)
help:
	@echo "==================== 4Ever 프로젝트 Makefile ===================="
	@echo ""
	@echo "📋 주요 명령어:"
	@echo ""
	@echo "🚀 개발 환경 관리:"
	@echo "  make dev              - 개발 모드 (빌드 + 시작)"
	@echo "  make build            - 모든 서비스 빌드"
	@echo "  make up               - 모든 서비스 시작"
	@echo "  make down             - 모든 서비스 중지"
	@echo "  make restart          - 모든 서비스 재시작"
	@echo "  make status           - 서비스 상태 확인"
	@echo "  make logs             - 전체 로그 확인 (실시간)"
	@echo "  make update-repos     - 모든 서비스 Git 최신화 (_4EVER_BE_*)"
	@echo ""
	@echo "🔧 개별 서비스 재빌드+재시작:"
	@echo "  make rebuild-gateway  - Gateway 재빌드 및 재시작"
	@echo "  make rebuild-auth     - Auth 재빌드 및 재시작"
	@echo "  make rebuild-alarm    - Alarm 재빌드 및 재시작"
	@echo "  make rebuild-business - Business 재빌드 및 재시작"
	@echo "  make rebuild-payment  - Payment 재빌드 및 재시작"
	@echo "  make rebuild-scm      - SCM 재빌드 및 재시작"
	@echo ""
	@echo "📋 개별 서비스 로그:"
	@echo "  make logs-gateway     - Gateway 로그"
	@echo "  make logs-auth        - Auth 로그"
	@echo "  make logs-alarm       - Alarm 로그"
	@echo "  make logs-business    - Business 로그"
	@echo "  make logs-payment     - Payment 로그"
	@echo "  make logs-scm         - SCM 로그"
	@echo ""
	@echo "🗄️  데이터베이스:"
	@echo "  make db-connect-auth      - Auth DB 접속"
	@echo "  make db-connect-alarm     - Alarm DB 접속"
	@echo "  make db-connect-business  - Business DB 접속"
	@echo "  make db-connect-payment   - Payment DB 접속"
	@echo "  make db-connect-scm       - SCM DB 접속"
	@echo "  make db-backup            - 모든 DB 백업"
	@echo ""
	@echo "📨 Kafka & Redis:"
	@echo "  make kafka-topics     - Kafka 토픽 목록"
	@echo "  make kafka-console TOPIC=<name>  - Kafka 컨슈머 콘솔"
	@echo "  make redis-cli        - Redis CLI 접속"
	@echo ""
	@echo "🔍 상태 확인:"
	@echo "  make health           - 모든 서비스 헬스체크"
	@echo "  make check-ports      - 포트 사용 현황"
	@echo "  make stats            - 리소스 사용량"
	@echo "  make mem-total        - 총 메모리 사용량"
	@echo ""
	@echo "🚀 프로덕션 환경 관리:"
	@echo "  make prod-init            - 프로덕션 환경 초기 세팅 (전체 배포)"
	@echo "  make prod-up              - 프로덕션 환경 전체 시작"
	@echo "  make prod-down            - 프로덕션 환경 전체 중지"
	@echo "  make prod-restart         - 프로덕션 환경 전체 재시작"
	@echo "  make prod-logs            - 프로덕션 환경 전체 로그"
	@echo "  make prod-status          - 프로덕션 환경 상태 확인"
	@echo ""
	@echo "🔄 프로덕션 개별 배포 (CI/CD 전용):"
	@echo "  make prod-deploy-gateway  - Gateway 프로덕션 배포"
	@echo "  make prod-deploy-auth     - Auth 프로덕션 배포"
	@echo "  make prod-deploy-alarm    - Alarm 프로덕션 배포"
	@echo "  make prod-deploy-business - Business 프로덕션 배포"
	@echo "  make prod-deploy-payment  - Payment 프로덕션 배포"
	@echo "  make prod-deploy-scm      - SCM 프로덕션 배포"
	@echo ""
	@echo "🧹 정리:"
	@echo "  make clean            - Docker 리소스 정리"
	@echo "  make clean-volumes    - 볼륨 포함 전체 제거"
	@echo ""
	@echo "💡 빠른 시작: make dev"
	@echo ""

##@ 리포지토리 관리

update-repos:
	@echo "🔄 모든 서비스 리포지토리를 최신화합니다 (_4EVER_BE_*)"
	@./scripts/update-repos.sh -r . -p "_4EVER_BE_*" --stash --no-rebase

##@ 개발 환경 관리

dev:
	@echo "🔥 개발 모드로 시작합니다..."
	@echo "🗑️  기존 Kafka 볼륨 삭제"
	docker volume rm autoever_kafka_data 2>/dev/null || true
	$(COMPOSE_DEV) up -d --build
	@echo "✅ 개발 환경이 시작되었습니다."
	@echo ""
	@make status

build:
	@echo "🔨 모든 서비스 이미지를 빌드합니다..."
	$(COMPOSE_DEV) build
	@echo "✅ 빌드 완료"

up:
	@echo "🚀 모든 서비스를 시작합니다..."
	$(COMPOSE_DEV) up -d
	@echo "✅ 서비스 시작 완료"
	@make status

down:
	@echo "🛑 모든 서비스를 중지합니다..."
	$(COMPOSE_DEV) down
	docker volume rm autoever_kafka_data 2>/dev/null || true
	@echo "✅ 서비스 중지 완료"

restart:
	@echo "🔄 모든 서비스를 재시작합니다..."
	$(COMPOSE_DEV) restart
	@echo "✅ 재시작 완료"

status:
	@echo "📊 서비스 상태:"
	@echo ""
	@$(COMPOSE_DEV) ps
	@echo ""
	@echo "🌐 서비스 포트:"
	@echo "  Gateway:   http://localhost:8080"
	@echo "  Auth:      http://localhost:8081"
	@echo "  Alarm:     http://localhost:8082"
	@echo "  Business:  http://localhost:8083"
	@echo "  Payment:   http://localhost:8084"
	@echo "  SCM:       http://localhost:8085"

logs:
	@echo "📋 전체 서비스 로그 (실시간)"
	$(COMPOSE_DEV) logs -f

##@ 개별 서비스 재빌드+재시작

rebuild-gateway:
	@echo "🔨 Gateway 재빌드 중..."
	$(COMPOSE_DEV) up -d --build gateway
	@echo "✅ Gateway 재빌드 완료. 로그를 확인합니다..."
	@$(COMPOSE_DEV) logs -f gateway

rebuild-auth:
	@echo "🔨 Auth 재빌드 중..."
	$(COMPOSE_DEV) up -d --build auth
	@echo "✅ Auth 재빌드 완료. 로그를 확인합니다..."
	@$(COMPOSE_DEV) logs -f auth

rebuild-alarm:
	@echo "🔨 Alarm 재빌드 중..."
	$(COMPOSE_DEV) up -d --build alarm
	@echo "✅ Alarm 재빌드 완료. 로그를 확인합니다..."
	@$(COMPOSE_DEV) logs -f alarm

rebuild-business:
	@echo "🔨 Business 재빌드 중..."
	$(COMPOSE_DEV) up -d --build business
	@echo "✅ Business 재빌드 완료. 로그를 확인합니다..."
	@$(COMPOSE_DEV) logs -f business

rebuild-payment:
	@echo "🔨 Payment 재빌드 중..."
	$(COMPOSE_DEV) up -d --build payment
	@echo "✅ Payment 재빌드 완료. 로그를 확인합니다..."
	@$(COMPOSE_DEV) logs -f payment

rebuild-scm:
	@echo "🔨 SCM 재빌드 중..."
	$(COMPOSE_DEV) up -d --build scm
	@echo "✅ SCM 재빌드 완료. 로그를 확인합니다..."
	@$(COMPOSE_DEV) logs -f scm

##@ 개별 서비스 시작

up-gateway:
	@echo "🚀 Gateway 시작"
	$(COMPOSE_DEV) up -d gateway

up-auth:
	@echo "🚀 Auth 시작"
	$(COMPOSE_DEV) up -d auth

up-alarm:
	@echo "🚀 Alarm 시작"
	$(COMPOSE_DEV) up -d alarm

up-business:
	@echo "🚀 Business 시작"
	$(COMPOSE_DEV) up -d business

up-payment:
	@echo "🚀 Payment 시작"
	$(COMPOSE_DEV) up -d payment

up-scm:
	@echo "🚀 SCM 시작"
	$(COMPOSE_DEV) up -d scm

##@ 개별 서비스 재시작

restart-gateway:
	@echo "🔄 Gateway 재시작"
	$(COMPOSE_DEV) restart gateway

restart-auth:
	@echo "🔄 Auth 재시작"
	$(COMPOSE_DEV) restart auth

restart-alarm:
	@echo "🔄 Alarm 재시작"
	$(COMPOSE_DEV) restart alarm

restart-business:
	@echo "🔄 Business 재시작"
	$(COMPOSE_DEV) restart business

restart-payment:
	@echo "🔄 Payment 재시작"
	$(COMPOSE_DEV) restart payment

restart-scm:
	@echo "🔄 SCM 재시작"
	$(COMPOSE_DEV) restart scm

##@ 개별 서비스 로그

logs-gateway:
	$(COMPOSE_DEV) logs -f gateway

logs-auth:
	$(COMPOSE_DEV) logs -f auth

logs-alarm:
	$(COMPOSE_DEV) logs -f alarm

logs-business:
	$(COMPOSE_DEV) logs -f business

logs-payment:
	$(COMPOSE_DEV) logs -f payment

logs-scm:
	$(COMPOSE_DEV) logs -f scm

logs-kafka:
	$(COMPOSE_DEV) logs -f kafka

logs-redis:
	$(COMPOSE_DEV) logs -f redis

##@ 데이터베이스 관리

db-up:
	@echo "🗄️  모든 데이터베이스 시작"
	$(COMPOSE_DEV) up -d db-auth db-alarm db-business db-payment db-scm

db-down:
	@echo "🗄️  모든 데이터베이스 중지"
	$(COMPOSE_DEV) stop db-auth db-alarm db-business db-payment db-scm

db-logs:
	@echo "📋 데이터베이스 로그"
	$(COMPOSE_DEV) logs -f db-auth db-alarm db-business db-payment db-scm

db-reset:
	@echo "⚠️  모든 데이터베이스를 초기화합니다 (데이터 삭제)"
	@echo "계속하려면 Enter를 누르세요..."
	@read
	$(COMPOSE_DEV) down
	docker volume rm autoever_auth_data autoever_alarm_data autoever_business_data autoever_payment_data autoever_scm_data 2>/dev/null || true
	$(COMPOSE_DEV) up -d db-auth db-alarm db-business db-payment db-scm

db-status:
	@echo "📊 데이터베이스 상태:"
	@echo ""
	@$(COMPOSE_DEV) ps db-auth db-alarm db-business db-payment db-scm
	@echo ""
	@echo "🌐 데이터베이스 접속 정보:"
	@echo "  Auth DB:        localhost:10002 (auth_user/auth_pass)"
	@echo "  Alarm DB:       localhost:10003 (alarm_user/alarm_pass)"
	@echo "  Business DB:    localhost:10004 (business_user/business_pass)"
	@echo "  Payment DB:     localhost:10006 (payment_user/payment_pass)"
	@echo "  SCM DB:         localhost:10007 (scm_user/scm_pass)"

db-connect-auth:
	@echo "🔗 Auth DB 접속"
	docker exec -it 4ever-db-auth psql -U auth_user -d auth_db

db-connect-alarm:
	@echo "🔗 Alarm DB 접속"
	docker exec -it 4ever-db-alarm psql -U alarm_user -d alarm_db

db-connect-business:
	@echo "🔗 Business DB 접속"
	docker exec -it 4ever-db-business psql -U business_user -d business_db

db-connect-payment:
	@echo "🔗 Payment DB 접속"
	docker exec -it 4ever-db-payment psql -U payment_user -d payment_db

db-connect-scm:
	@echo "🔗 SCM DB 접속"
	docker exec -it 4ever-db-scm psql -U scm_user -d scm_db

db-backup:
	@mkdir -p backups
	@echo "💾 데이터베이스 백업 중..."
	@docker exec 4ever-db-auth pg_dump -U auth_user auth_db > backups/auth_db_$$(date +%Y%m%d_%H%M%S).sql
	@docker exec 4ever-db-alarm pg_dump -U alarm_user alarm_db > backups/alarm_db_$$(date +%Y%m%d_%H%M%S).sql
	@docker exec 4ever-db-business pg_dump -U business_user business_db > backups/business_db_$$(date +%Y%m%d_%H%M%S).sql
	@docker exec 4ever-db-payment pg_dump -U payment_user payment_db > backups/payment_db_$$(date +%Y%m%d_%H%M%S).sql
	@docker exec 4ever-db-scm pg_dump -U scm_user scm_db > backups/scm_db_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ 백업 완료: backups/"

##@ Kafka 관리

kafka-up:
	@echo "📨 Kafka와 Zookeeper 시작"
	$(COMPOSE_DEV) up -d zookeeper kafka

kafka-down:
	@echo "📨 Kafka와 Zookeeper 중지"
	$(COMPOSE_DEV) stop zookeeper kafka

kafka-logs:
	@echo "📋 Kafka 로그"
	$(COMPOSE_DEV) logs -f kafka

kafka-topics:
	@echo "📝 Kafka 토픽 목록:"
	docker exec 4ever-kafka kafka-topics --bootstrap-server localhost:9092 --list

kafka-create-topic:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ 사용법: make kafka-create-topic TOPIC=topic-name"; \
		exit 1; \
	fi
	@echo "📝 Kafka 토픽 생성: $(TOPIC)"
	docker exec 4ever-kafka kafka-topics --bootstrap-server localhost:9092 --create --topic $(TOPIC) --partitions 3 --replication-factor 1

kafka-console:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ 사용법: make kafka-console TOPIC=topic-name"; \
		exit 1; \
	fi
	@echo "📨 Kafka 컨슈머 콘솔: $(TOPIC)"
	docker exec -it 4ever-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic $(TOPIC) --from-beginning

##@ Redis 관리

redis-up:
	@echo "🔴 Redis 시작"
	$(COMPOSE_DEV) up -d redis

redis-down:
	@echo "🔴 Redis 중지"
	$(COMPOSE_DEV) stop redis

redis-logs:
	@echo "📋 Redis 로그"
	$(COMPOSE_DEV) logs -f redis

redis-cli:
	@echo "🔗 Redis CLI 접속"
	docker exec -it 4ever-redis redis-cli -a redis_password

redis-monitor:
	@echo "👁️  Redis 명령 모니터링"
	docker exec -it 4ever-redis redis-cli -a redis_password monitor

redis-flush:
	@echo "⚠️  Redis의 모든 데이터를 삭제합니다."
	@echo "계속하려면 Enter를 누르세요..."
	@read
	docker exec 4ever-redis redis-cli -a redis_password FLUSHALL

##@ 인프라 통합 관리

infra-up:
	@echo "🏗️  모든 인프라(DB, Kafka, Redis) 시작"
	$(COMPOSE_DEV) up -d zookeeper kafka redis db-auth db-alarm db-business db-payment db-scm

infra-down:
	@echo "🏗️  모든 인프라(DB, Kafka, Redis) 중지"
	$(COMPOSE_DEV) stop zookeeper kafka redis db-auth db-alarm db-business db-payment db-scm

infra-logs:
	@echo "📋 모든 인프라 로그"
	$(COMPOSE_DEV) logs -f zookeeper kafka redis db-auth db-alarm db-business db-payment db-scm

infra-status:
	@echo "📊 인프라 서비스 상태:"
	@echo ""
	@$(COMPOSE_DEV) ps zookeeper kafka redis db-auth db-alarm db-business db-payment db-scm
	@echo ""
	@echo "🌐 인프라 서비스 접속 정보:"
	@echo "  Kafka:          localhost:9092"
	@echo "  Zookeeper:      localhost:2181"
	@echo "  Redis:          localhost:6379 (password: redis_password)"

##@ 상태 확인

health:
	@echo "🏥 서비스 헬스체크..."
	@echo ""
	@echo "Gateway (8080):"
	@curl -s http://localhost:8080/actuator/health | head -1 || echo "❌ 연결 실패"
	@echo ""
	@echo "Auth (8081):"
	@curl -s http://localhost:8081/actuator/health | head -1 || echo "❌ 연결 실패"
	@echo ""
	@echo "Alarm (8082):"
	@curl -s http://localhost:8082/actuator/health | head -1 || echo "❌ 연결 실패"
	@echo ""
	@echo "Business (8083):"
	@curl -s http://localhost:8083/actuator/health | head -1 || echo "❌ 연결 실패"
	@echo ""
	@echo "Payment (8084):"
	@curl -s http://localhost:8084/payments/health | head -1 || echo "❌ 연결 실패"
	@echo ""
	@echo "SCM (8085):"
	@curl -s http://localhost:8085/actuator/health | head -1 || echo "❌ 연결 실패"
	@echo ""

check-ports:
	@echo "📡 포트 사용 현황:"
	@echo ""
	@lsof -i :8080 || echo "  8080 (Gateway):  사용 안 함"
	@lsof -i :8081 || echo "  8081 (Auth):     사용 안 함"
	@lsof -i :8082 || echo "  8082 (Alarm):    사용 안 함"
	@lsof -i :8083 || echo "  8083 (Business): 사용 안 함"
	@lsof -i :8084 || echo "  8084 (Payment):  사용 안 함"
	@lsof -i :8085 || echo "  8085 (SCM):      사용 안 함"

stats:
	@echo "📊 컨테이너 리소스 사용량:"
	@echo ""
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

mem-total:
	@echo "💾 컨테이너 총 메모리 사용량:"
	@echo ""
	@docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"
	@echo ""
	@echo "📊 총 메모리:"
	@docker stats --no-stream --format "{{.MemUsage}}" | awk -F'/' '{print $$1}' | sed 's/GiB/*1024/;s/MiB//' | bc 2>/dev/null | awk '{sum+=$$1} END {if(sum>=1024) printf "  사용량: %.2f GiB\n", sum/1024; else printf "  사용량: %.2f MiB\n", sum}'

##@ 정리

clean:
	@echo "🧹 Docker 리소스 정리"
	$(COMPOSE_DEV) down
	docker system prune -f
	@echo "✅ 정리 완료"

clean-volumes:
	@echo "⚠️  모든 컨테이너와 볼륨이 삭제됩니다."
	@echo "계속하려면 'yes'를 입력하세요:"
	@read answer; \
	if [ "$$answer" = "yes" ]; then \
		$(COMPOSE_DEV) down -v; \
		echo "✅ 모든 컨테이너와 볼륨이 삭제되었습니다."; \
	else \
		echo "❌ 취소되었습니다."; \
	fi

clean-all:
	@echo "⚠️  모든 Docker 리소스가 삭제됩니다."
	@echo "계속하려면 'yes'를 입력하세요:"
	@read answer; \
	if [ "$$answer" = "yes" ]; then \
		docker system prune -af --volumes; \
		echo "✅ 모든 Docker 리소스가 삭제되었습니다."; \
	else \
		echo "❌ 취소되었습니다."; \
	fi

##@ 프로덕션 환경 관리

prod-init:
	@echo "========================================="
	@echo "🚀 프로덕션 환경 초기 세팅 시작"
	@echo "========================================="
	@echo ""
	@echo "📋 사전 체크리스트:"
	@echo "  ✓ .env.prod 파일 준비"
	@echo "  ✓ docker-compose.prod.yml 파일 준비"
	@echo "  ✓ S3에 application.yml 파일들 업로드"
	@echo "  ✓ application.yml 파일들 다운로드 완료"
	@echo ""
	@echo "1️⃣ 인프라 서비스 시작 (Zookeeper, Kafka, Redis)"
	$(COMPOSE_PROD) up -d zookeeper kafka redis
	@echo "⏳ Kafka 초기화 대기 중 (30초)..."
	@sleep 30
	@echo ""
	@echo "2️⃣ 데이터베이스 서비스 시작"
	$(COMPOSE_PROD) up -d db-auth db-alarm db-business db-payment db-scm
	@echo "⏳ 데이터베이스 초기화 대기 중 (15초)..."
	@sleep 15
	@echo ""
	@echo "3️⃣ Nginx 및 Certbot 서비스 시작"
	$(COMPOSE_PROD) up -d nginx certbot
	@echo ""
	@echo "4️⃣ 애플리케이션 서비스 시작"
	$(COMPOSE_PROD) up -d gateway auth alarm business payment scm
	@echo "⏳ 애플리케이션 초기화 대기 중 (10초)..."
	@sleep 10
	@echo ""
	@echo "========================================="
	@echo "✅ 프로덕션 환경 초기 세팅 완료"
	@echo "========================================="
	@echo ""
	@make prod-status

prod-up:
	@echo "🚀 프로덕션 환경 전체 시작"
	$(COMPOSE_PROD) up -d
	@echo "✅ 프로덕션 환경 시작 완료"
	@make prod-status

prod-down:
	@echo "🛑 프로덕션 환경 전체 중지"
	$(COMPOSE_PROD) down
	@echo "✅ 프로덕션 환경 중지 완료"

prod-restart:
	@echo "🔄 프로덕션 환경 전체 재시작"
	$(COMPOSE_PROD) restart
	@echo "✅ 프로덕션 환경 재시작 완료"
	@make prod-status

prod-logs:
	@echo "📋 프로덕션 환경 전체 로그 (실시간)"
	$(COMPOSE_PROD) logs -f

prod-status:
	@echo "📊 프로덕션 환경 상태:"
	@echo ""
	@$(COMPOSE_PROD) ps
	@echo ""
	@echo "🌐 서비스 엔드포인트:"
	@echo "  Gateway:   http://your-domain.com:8080"
	@echo "  Auth:      http://your-domain.com:8081"
	@echo "  Alarm:     http://your-domain.com:8082"
	@echo "  Business:  http://your-domain.com:8083"
	@echo "  Payment:   http://your-domain.com:8084"
	@echo "  SCM:       http://your-domain.com:8085"
	@echo ""
	@echo "🗄️  인프라 서비스:"
	@echo "  Kafka:     localhost:9092"
	@echo "  Redis:     localhost:6379"
	@echo "  Zookeeper: localhost:2181"

##@ 프로덕션 개별 배포 (CI/CD 전용)

prod-deploy-gateway:
	@echo "🚀 [PROD] Gateway 배포 시작..."
	@echo "📥 최신 이미지 Pull..."
	docker pull hojipkim/everp_gateway:latest
	@echo "🔄 Gateway 서비스 재시작..."
	$(COMPOSE_PROD) up -d --no-deps gateway
	@echo "✅ Gateway 배포 완료"
	@sleep 5
	@docker ps --filter "name=4ever-gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

prod-deploy-auth:
	@echo "🚀 [PROD] Auth 배포 시작..."
	@echo "📥 최신 이미지 Pull..."
	docker pull hojipkim/everp_user:latest
	@echo "🔄 Auth 서비스 재시작..."
	$(COMPOSE_PROD) up -d --no-deps auth
	@echo "✅ Auth 배포 완료"
	@sleep 5
	@docker ps --filter "name=4ever-auth" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

prod-deploy-alarm:
	@echo "🚀 [PROD] Alarm 배포 시작..."
	@echo "📥 최신 이미지 Pull..."
	docker pull hojipkim/everp_alarm:latest
	@echo "🔄 Alarm 서비스 재시작..."
	$(COMPOSE_PROD) up -d --no-deps alarm
	@echo "✅ Alarm 배포 완료"
	@sleep 5
	@docker ps --filter "name=4ever-alarm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

prod-deploy-business:
	@echo "🚀 [PROD] Business 배포 시작..."
	@echo "📥 최신 이미지 Pull..."
	docker pull hojipkim/everp_business:latest
	@echo "🔄 Business 서비스 재시작..."
	$(COMPOSE_PROD) up -d --no-deps business
	@echo "✅ Business 배포 완료"
	@sleep 5
	@docker ps --filter "name=4ever-business" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

prod-deploy-payment:
	@echo "🚀 [PROD] Payment 배포 시작..."
	@echo "📥 최신 이미지 Pull..."
	docker pull hojipkim/everp_payment:latest
	@echo "🔄 Payment 서비스 재시작..."
	$(COMPOSE_PROD) up -d --no-deps payment
	@echo "✅ Payment 배포 완료"
	@sleep 5
	@docker ps --filter "name=4ever-payment" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

prod-deploy-scm:
	@echo "🚀 [PROD] SCM 배포 시작..."
	@echo "📥 최신 이미지 Pull..."
	docker pull hojipkim/everp_scm:latest
	@echo "🔄 SCM 서비스 재시작..."
	$(COMPOSE_PROD) up -d --no-deps scm
	@echo "✅ SCM 배포 완료"
	@sleep 5
	@docker ps --filter "name=4ever-scm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

##@ 통합 명령어

quick-start:
	@echo "⚡ 빠른 시작 (핵심 서비스만)"
	$(COMPOSE_DEV) up -d zookeeper kafka redis
	@echo "⏳ Kafka 준비 대기 중..."
	@sleep 10
	$(COMPOSE_DEV) up -d gateway auth payment
	@echo "✅ 핵심 서비스 시작 완료"
	@make status

full-restart:
	@echo "🔄 전체 재시작 (down → build → up)"
	$(COMPOSE_DEV) down
	$(COMPOSE_DEV) up -d --build
	@echo "✅ 전체 재시작 완료"
	@make status
