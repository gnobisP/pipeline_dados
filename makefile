# =============================================
# VARIÁVEIS DE AMBIENTE E CONFIGURAÇÃO
# =============================================

# Diretórios
PROJECT_DIR := $(shell pwd)
OUTPUT_DIR := $(PROJECT_DIR)/data
AIRFLOW_PATH := $(PROJECT_DIR)/airflow
CSV_PATH := $(PROJECT_DIR)/data/order_details.csv

# Caminhos para ambientes virtuais
VENV_AIRFLOW := $(PROJECT_DIR)/venv_airflow/bin/activate
VENV_MELTANO := $(PROJECT_DIR)/venv_meltano/bin/activate
VENV_TEST := $(PROJECT_DIR)/venv/bin/activate

# Comandos de ativação
ACTIVATE_VENV_AIRFLOW := . $(VENV_AIRFLOW) && cd $(PROJECT_DIR)
ACTIVATE_VENV_MELTANO := . $(VENV_MELTANO)
ACTIVATE_VENV_TEST := . $(VENV_TEST)

# =============================================
# TARGETS PRINCIPAIS
# =============================================

setup: setup-docker setup-meltano setup-airflow
	@echo "Setup completo: Docker, Meltano e Airflow configurados"

start: start-airflow
	@echo "✅ Todos os sistemas foram iniciados!"
	@echo "• Airflow: http://localhost:8089"
	@echo "• Meltano: Pronto para executar pipelines"


# =============================================
# DOCKER
# =============================================
setup-docker:
	docker compose -f 'docker-compose.yml' up -d --build 'db' && \
	docker compose -f 'docker-compose.yml' up -d --build 'data_warehouse_db'
	@echo "Serviços Docker configurados e iniciados"

# =============================================
# MELTANO
# =============================================
setup-meltano: install-meltano configure-meltano
	@echo "Meltano instalado e configurado"

install-meltano: venv-meltano
	venv_meltano/bin/pip3 install --upgrade pip
	venv_meltano/bin/pip3 install meltano
	@echo "Meltano instalado no ambiente virtual"

configure-meltano: create-taps create-loaders
	@echo "Taps e loaders do Meltano configurados"

create-taps: create-tap-parquet create-tap-csv create-tap-postgres
	@echo "Todos os taps criados"

create-loaders: create-load-parquet create-load-jsonl create-load-csv create-load-postgres
	@echo "Todos os loaders criados"

run-etl:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	DATE=$$(date +"%Y-%m-%d") meltano elt tap-csv target-csv-csv && \
	DATE=$$(date +"%Y-%m-%d") meltano elt tap-postgres target-postgres-csv && \
	DATE=$$(date +"%Y-%m-%d") meltano elt tap-csv-fase2 target-postgres
	@echo "Pipeline ETL executado"


# =============================================
# AIRFLOW
# =============================================
setup-airflow: install-airflow configure-airflow-user
	@echo "Airflow instalado e configurado"
install-airflow: venv-airflow
	$(ACTIVATE_VENV_AIRFLOW) && \
	pip install "apache-airflow[celery]==2.10.4" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.4/constraints-3.12.txt" && \
	export AIRFLOW_HOME=$(AIRFLOW_PATH) && \
	airflow db migrate
	@echo "Airflow instalado no ambiente virtual"

configure-airflow-user:
	$(ACTIVATE_VENV_AIRFLOW) && \
	export AIRFLOW_HOME=$(AIRFLOW_PATH) && \
	airflow db migrate && \
	airflow users create --username admin --firstname admin --lastname admin --role Admin --email admin@admin.com --password 123456
	@echo "Usuário admin do Airflow configurado"

start-airflow: start-airflow-webserver start-airflow-scheduler
	@echo "Airflow webserver e scheduler iniciados em background"

start-airflow-webserver:
	. $(VENV_PATH_AIRFLOW) && \
	export AIRFLOW_HOME=$(AIRFLOW_PATH) && \
	airflow webserver -p 8089

start-airflow-scheduler:
	. $(VENV_PATH_AIRFLOW) && \
	export AIRFLOW_HOME=$(AIRFLOW_PATH) && \
	airflow scheduler

stop-airflow:
	@if [ -f airflow-webserver.pid ]; then \
		echo "Parando webserver (PID: $$(cat airflow-webserver.pid))"; \
		kill $$(cat airflow-webserver.pid); \
		rm airflow
run-dag:
	$(ACTIVATE_VENV_AIRFLOW) && \
	export AIRFLOW_HOME=$(AIRFLOW_PATH) && \
	airflow dags trigger -e 2025-10-01 
	@echo "DAG executada"
# =============================================
# AMBIENTES VIRTUAIS
# =============================================

venv-airflow:
	python3.10 -m venv venv_airflow
	@echo "Ambiente virtual para Airflow criado"

venv-meltano:
	python3.10 -m venv venv_meltano
	@echo "Ambiente virtual para Meltano criado"

# =============================================
# TARGETS INDIVIDUAIS PARA TAPS E LOADERS
# =============================================

# Taps
create-tap-postgres:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add extractor tap-postgres --variant meltanolabs && \
	meltano config tap-postgres set host localhost && \
	meltano config tap-postgres set port 5432 && \
	meltano config tap-postgres set dbname northwind && \
	meltano config tap-postgres set user northwind_user && \
	meltano config tap-postgres set password thewindisblowing && \
	meltano config tap-postgres set database northwind && \
	meltano config tap-postgres set default_replication_method FULL_TABLE && \
	meltano config tap-postgres set filter_schemas '["public"]' && \
	meltano config tap-postgres set max_record_count 10000 && \
	meltano config tap-postgres set dates_as_string false && \
	meltano config tap-postgres set json_as_object false && \
	meltano config tap-postgres set ssl_enable false
	@echo "Tap PostgreSQL configurado"

create-tap-parquet:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add extractor tap-parquet
	@echo "Tap Parquet configurado"

create-tap-csv:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add extractor tap-csv --variant meltanolabs && \
	meltano config tap-csv set files '[{"entity": "order_details", "path": "$(CSV_PATH)", "keys": ["order_id"], "format": "csv"}]'
	@echo "Tap CSV configurado"

# Loaders
create-load-parquet:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add loader target-parquet && \
	meltano config target-parquet set destination_path $(OUTPUT_DIR)
	@echo "Loader Parquet configurado"

create-load-jsonl:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add loader target-jsonl && \
	meltano config target-jsonl set destination_path $(OUTPUT_DIR)/jsonl
	@echo "Loader JSONL configurado"

create-load-csv:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add loader target-csv && \
	meltano config target-csv set destination_path $(OUTPUT_DIR)
	@echo "Loader CSV configurado"

create-load-postgres:
	$(ACTIVATE_VENV_MELTANO) && \
	cd metano-project && \
	meltano add loader target-postgres && \
	meltano config target-postgres set host localhost && \
	meltano config target-postgres set port 5433 && \
	meltano config target-postgres set user dw_user && \
	meltano config target-postgres set password dw_password && \
	meltano config target-postgres set dbname data_warehouse
	@echo "Loader PostgreSQL configurado"

# =============================================
# UTILITÁRIOS
# =============================================

clean:
	@echo "Limpando ambientes virtuais..."
	rm -rf venv_airflow venv_meltano venv
	@echo "Ambientes virtuais removidos"
	
#sudo lsof -i :5433 docker-compose
#SUDO lsof -i :8793 airflow-scheduler
#sudo lsof -i :8089 airflow-webserver
#sudo kill -9 <PID>