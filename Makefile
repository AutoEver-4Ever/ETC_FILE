.PHONY: help build up down restart logs clean status db-up db-down db-logs db-reset db-status kafka-up kafka-down redis-up redis-down infra-up infra-down build-prod up-prod down-prod restart-prod logs-prod status-prod clean-prod deploy-prod

# 도움말 표시 (기본 명령어)
help:
	@echo "🚀 AutoEver Docker 관리 명령어"
	@echo ""
	@echo "📋 서비스 관리:"
	@echo "  make build     - 모든 서비스 이미지 빌드"
	@echo "  make up        - 모든 서비스 시작"
	@echo "  make down      - 모든 서비스 중지"
	@echo "  make restart   - 모든 서비스 재시작"
	@echo "  make status    - 모든 서비스 상태 확인"
	@echo "  make logs      - 모든 서비스 로그 실시간 확인"
	@echo "  make clean     - 사용하지 않는 Docker 리소스 정리"
	@echo "  make dev       - 개발 모드 (빌드 + 시작 + 상태확인)"
	@echo ""
	@echo "🗄️  데이터베이스 관리:"
	@echo "  make db-up     - 모든 데이터베이스 시작"
	@echo "  make db-down   - 모든 데이터베이스 중지"
	@echo "  make db-logs   - 데이터베이스 로그 확인"
	@echo "  make db-reset  - 모든 데이터베이스 초기화 (데이터 삭제)"
	@echo "  make db-status - 데이터베이스 상태 및 접속 정보 확인"
	@echo ""
	@echo "🔧 개별 서비스 명령어:"
	@echo "  make up-<service>      - 개별 서비스 시작 (gateway, auth, alarm, business, cb, payment, scm)"
	@echo "  make logs-<service>    - 개별 서비스 로그 확인"
	@echo "  make restart-<service> - 개별 서비스 재시작"
	@echo ""
	@echo "🔗 데이터베이스 접속:"
	@echo "  make db-connect-<service> - 개별 데이터베이스 접속"
	@echo ""
	@echo "💡 사용 예시:"
	@echo "  make dev                  # 개발 환경 전체 시작"
	@echo "  make up-gateway          # Gateway 서비스만 시작"
	@echo "  make db-connect-auth     # Auth 데이터베이스 접속"

# 서비스 상태 확인
status:
	@echo "📊 서비스 상태:"
	docker compose ps
	@echo "🗄️ 데이터베이스 상태:"
	docker compose ps db-gateway db-auth db-alarm db-business db-cb db-payment db-scm

# 모든 서비스 이미지 빌드 (병렬)
build:
	docker compose build

# 모든 서비스 시작
up:
	@echo "🚀 모든 서비스를 시작"
	docker compose up -d
	@echo "✅ 서비스 시작 완료"
	@echo "📊 서비스 상태 확인: make status"
	@echo "📋 로그 확인: make logs"

# 모든 서비스 중지
down:
	@echo "🛑 모든 서비스를 중지"
	docker compose down
	@echo "🗑️  Kafka 볼륨을 삭제"
	docker volume rm autoever_kafka_data 2>/dev/null || true
	@echo "✅ 서비스 중지 완료!"

# 모든 서비스 재시작
restart:
	@echo "🔄 모든 서비스를 재시작"
	docker compose restart
	@echo "✅ 서비스 재시작 완료!"

# 실시간 로그 확인
logs:
	@echo "📋 모든 서비스의 로그를 실시간으로 표시"
	docker compose logs -f

# 시스템 정리
clean:
	@echo "🧹 사용하지 않는 Docker 리소스를 정리"
	docker compose down
	docker system prune -f
	docker volume prune -f
	@echo "✅ 정리 완료"

# 개별 서비스 시작
up-gateway:
	@echo "🚀 Gateway 서비스를 시작"
	docker compose up -d gateway

up-auth:
	@echo "🚀 Auth 서비스를 시작"
	docker compose up -d auth

up-alarm:
	@echo "🚀 Alarm 서비스를 시작"
	docker compose up -d alarm

up-business:
	@echo "🚀 Business 서비스를 시작"
	docker compose up -d business

up-cb:
	@echo "🚀 Circuit Breaker 서비스를 시작"
	docker compose up -d circuit-breaker

up-payment:
	@echo "🚀 Payment 서비스를 시작"
	docker compose up -d payment

up-scm:
	@echo "🚀 SCM 서비스를 시작"
	docker compose up -d scm

# 개별 서비스 로그
logs-gateway:
	docker compose logs -f gateway

logs-auth:
	docker compose logs -f auth

logs-alarm:
	docker compose logs -f alarm

logs-business:
	docker compose logs -f business

logs-cb:
	docker compose logs -f circuit-breaker

logs-payment:
	docker compose logs -f payment

logs-scm:
	docker compose logs -f scm

# 개별 서비스 재시작
restart-gateway:
	docker compose restart gateway

restart-auth:
	docker compose restart auth

restart-alarm:
	docker compose restart alarm

restart-business:
	docker compose restart business

restart-cb:
	docker compose restart circuit-breaker

restart-payment:
	docker compose restart payment

restart-scm:
	docker compose restart scm

# 빠른 개발 모드 (빌드 + 시작)
dev:
	@echo "🔥 개발 모드로 시작합니다..."
	@echo "🗑️  기존 Kafka 볼륨을 삭제"
	docker volume rm autoever_kafka_data 2>/dev/null || true
	make build
	make up
	make status

# 데이터베이스 관리
db-up:
	@echo "🗄️ 모든 데이터베이스를 시작"
	docker compose up -d db-gateway db-auth db-alarm db-business db-cb db-payment db-scm

db-down:
	@echo "🗄️ 모든 데이터베이스를 중지"
	docker compose stop db-gateway db-auth db-alarm db-business db-cb db-payment db-scm

db-logs:
	@echo "📋 데이터베이스 로그를 확인"
	docker compose logs -f db-gateway db-auth db-alarm db-business db-cb db-payment db-scm

db-reset:
	@echo "🗄️ 모든 데이터베이스를 초기화"
	docker compose down
	docker volume rm autoever_gateway_data autoever_auth_data autoever_alarm_data autoever_business_data autoever_cb_data autoever_payment_data autoever_scm_data 2>/dev/null || true
	make db-up

# 개별 데이터베이스 접속
db-connect-gateway:
	@echo "🔗 Gateway 데이터베이스에 접속"
	docker exec -it 4ever-db-gateway psql -U gateway_user -d gateway_db

db-connect-auth:
	@echo "🔗 Auth 데이터베이스에 접속"
	docker exec -it 4ever-db-auth psql -U auth_user -d auth_db

db-connect-alarm:
	@echo "🔗 Alarm 데이터베이스에 접속"
	docker exec -it 4ever-db-alarm psql -U alarm_user -d alarm_db

db-connect-business:
	@echo "🔗 Business 데이터베이스에 접속"
	docker exec -it 4ever-db-business psql -U business_user -d business_db

db-connect-cb:
	@echo "🔗 Circuit Breaker 데이터베이스에 접속"
	docker exec -it 4ever-db-cb psql -U cb_user -d cb_db

db-connect-payment:
	@echo "🔗 Payment 데이터베이스에 접속"
	docker exec -it 4ever-db-payment psql -U payment_user -d payment_db

db-connect-scm:
	@echo "🔗 SCM 데이터베이스에 접속"
	docker exec -it 4ever-db-scm psql -U scm_user -d scm_db

# 데이터베이스 상태 확인
db-status:
	@echo "📊 데이터베이스 상태:"
	@echo ""
	docker compose ps db-gateway db-auth db-alarm db-business db-cb db-payment db-scm
	@echo ""
	@echo "🌐 데이터베이스 접속 정보:"
	@echo "  Gateway DB:     localhost:10001 (gateway_user/gateway_pass)"
	@echo "  Auth DB:        localhost:10002 (auth_user/auth_pass)"
	@echo "  Alarm DB:       localhost:10003 (alarm_user/alarm_pass)"
	@echo "  Business DB:    localhost:10004 (business_user/business_pass)"
	@echo "  Circuit Breaker DB: localhost:10005 (cb_user/cb_pass)"
	@echo "  Payment DB:     localhost:10006 (payment_user/payment_pass)"
	@echo "  SCM DB:         localhost:10007 (scm_user/scm_pass)"

# Kafka 관리
kafka-up:
	@echo "📨 Kafka와 Zookeeper를 시작"
	docker compose up -d zookeeper kafka

kafka-down:
	@echo "📨 Kafka와 Zookeeper를 중지"
	docker compose stop zookeeper kafka

kafka-logs:
	@echo "📋 Kafka 로그를 확인"
	docker compose logs -f kafka

kafka-topics:
	@echo "📝 Kafka 토픽 목록을 확인"
	docker exec 4ever-kafka kafka-topics --bootstrap-server localhost:9092 --list

kafka-create-topic:
	@echo "📝 Kafka 토픽을 생성. 사용법: make kafka-create-topic TOPIC=topic-name"
	@if [ -z "$(TOPIC)" ]; then echo "❌ TOPIC 파라미터가 필요합니다. 예: make kafka-create-topic TOPIC=my-topic"; exit 1; fi
	docker exec 4ever-kafka kafka-topics --bootstrap-server localhost:9092 --create --topic $(TOPIC) --partitions 3 --replication-factor 1

# Redis 관리
redis-up:
	@echo "🔴 Redis를 시작"
	docker compose up -d redis

redis-down:
	@echo "🔴 Redis를 중지"
	docker compose stop redis

redis-logs:
	@echo "📋 Redis 로그를 확인"
	docker compose logs -f redis

redis-cli:
	@echo "🔗 Redis CLI에 접속"
	docker exec -it 4ever-redis redis-cli -a redis_password

redis-monitor:
	@echo "👁️ Redis 명령어를 실시간으로 모니터링"
	docker exec -it 4ever-redis redis-cli -a redis_password monitor

# 인프라 통합 관리
infra-up:
	@echo "🏗️ 모든 인프라(DB, Kafka, Redis)를 시작"
	make db-up
	make kafka-up
	make redis-up

infra-down:
	@echo "🏗️ 모든 인프라(DB, Kafka, Redis)를 중지"
	docker compose stop zookeeper kafka redis db-gateway db-auth db-alarm db-business db-cb db-payment db-scm

infra-logs:
	@echo "📋 모든 인프라 로그를 확인합니다..."
	docker compose logs -f zookeeper kafka redis db-gateway db-auth db-alarm db-business db-cb db-payment db-scm

infra-status:
	@echo "📊 인프라 서비스 상태:"
	@echo ""
	docker compose ps zookeeper kafka redis db-gateway db-auth db-alarm db-business db-cb db-payment db-scm
	@echo ""
	@echo "🌐 인프라 서비스 접속 정보:"
	@echo "  Kafka:          localhost:9092"
	@echo "  Zookeeper:      localhost:2181"
	@echo "  Redis:          localhost:6379 (password: redis_password)"
	@echo ""
	@echo "🗄️ 데이터베이스:"
	@echo "  Gateway DB:     localhost:10001 (gateway_user/gateway_pass)"
	@echo "  Auth DB:        localhost:10002 (auth_user/auth_pass)"
	@echo "  Alarm DB:       localhost:10003 (alarm_user/alarm_pass)"
	@echo "  Business DB:    localhost:10004 (business_user/business_pass)"
	@echo "  Circuit Breaker DB: localhost:10005 (cb_user/cb_pass)"
	@echo "  Payment DB:     localhost:10006 (payment_user/payment_pass)"
	@echo "  SCM DB:         localhost:10007 (scm_user/scm_pass)"

# 프로덕션 환경 관리
build-prod:
	@echo "🏭 프로덕션용 이미지를 빌드 (테스트 포함)"
	docker compose -f docker-compose-prod.yml build

up-prod:
	@echo "🏭 프로덕션 환경으로 모든 서비스를 시작"
	docker compose -f docker-compose-prod.yml up -d
	@echo "✅ 프로덕션 서비스 시작 완료!"
	@echo "📊 서비스 상태 확인: make status-prod"
	@echo "📋 로그 확인: make logs-prod"

down-prod:
	@echo "🏭 프로덕션 환경의 모든 서비스를 중지"
	docker compose -f docker-compose-prod.yml down
	@echo "✅ 프로덕션 서비스 중지 완료!"

restart-prod:
	@echo "🏭 프로덕션 환경의 모든 서비스를 재시작"
	docker compose -f docker-compose-prod.yml restart
	@echo "✅ 프로덕션 서비스 재시작 완료!"

logs-prod:
	@echo "📋 프로덕션 환경의 모든 서비스 로그를 실시간으로 표시"
	docker compose -f docker-compose-prod.yml logs -f

status-prod:
	@echo "📊 프로덕션 환경 서비스 상태:"
	@echo ""
	docker compose -f docker-compose-prod.yml ps
	@echo ""
	@echo "🌐 프로덕션 서비스 접속 정보:"
	@echo "  Gateway:        http://localhost:8080"
	@echo "  Alarm:          http://localhost:8081"
	@echo "  Auth:           http://localhost:8082"
	@echo "  Business:       http://localhost:8083"
	@echo "  Circuit Breaker: http://localhost:8084"
	@echo "  Payment:        http://localhost:8085"
	@echo "  SCM:            http://localhost:8086"

clean-prod:
	@echo "🧹 프로덕션 환경의 사용하지 않는 Docker 리소스를 정리"
	docker compose -f docker-compose-prod.yml down
	docker system prune -f
	docker volume prune -f
	@echo "✅ 프로덕션 환경 정리 완료!"

# 빠른 프로덕션 배포 (빌드 + 시작)
deploy-prod:
	@echo "🚀 프로덕션 배포를 시작"
	make build-prod
	make up-prod
	make status-prod