#!/bin/bash
VENV_PATH="/home/gnobisp/Documents/pipeline_dados/venv_meltano/bin/activate"
PROJECT_PATH="/home/gnobisp/Documents/pipeline_dados/metano-project"

# Ativa o ambiente virtual
source "$VENV_PATH"

# Função para extrair dados do CSV
extract_csv() {
    set -e  # Para o script em caso de erro
    cd "$PROJECT_PATH"
    DATE=$(date +"%Y-%m-%d--%H") meltano elt tap-csv target-csv-csv
}

# Chama a função
extract_csv