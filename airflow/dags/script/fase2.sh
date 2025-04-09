#!/bin/bash
VENV_PATH="/home/gnobisp/Documents/pipeline_dados/venv_meltano/bin/activate"
PROJECT_PATH="/home/gnobisp/Documents/pipeline_dados/metano-project"

DATE=$1

# Ativa o ambiente virtual
source "$VENV_PATH"

# Função para extrair dados do Postgres
extract_fase2() {
    set -e  # Para o script em caso de erro
    cd "$PROJECT_PATH" || { echo "Falha ao acessar $PROJECT_PATH"; exit 1; }
    DATE="$DATE" meltano elt tap-csv-fase2 target-postgres
}

# Chama a função
extract_fase2