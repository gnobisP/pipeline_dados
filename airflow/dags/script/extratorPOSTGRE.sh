#!/bin/bash
VENV_PATH="/home/gnobisp/Documents/pipeline_dados/venv_meltano/bin/activate"
PROJECT_PATH="/home/gnobisp/Documents/pipeline_dados/metano-project"

DATE=$1

# Ativa o ambiente virtual
source "$VENV_PATH"

# Função para extrair dados do Postgres
extract_postgres() {
    set -e  # Para o script em caso de erro
    cd "$PROJECT_PATH"
    DATE="$DATE" meltano elt tap-postgres target-postgres-csv
}

# Chama a função
extract_postgres