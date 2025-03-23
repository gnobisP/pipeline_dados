#!/bin/bash

# Defina o caminho do ambiente virtual
VENV_PATH="/home/gnobisp/Documents/pipeline_dados/venv_meltano/bin/activate"
PROJECT_PATH="/home/gnobisp/Documents/pipeline_dados/metano-project"

# Ativa o ambiente virtual
source "$VENV_PATH"

# Obtém a data atual para organizar as pastas
CURRENT_DATE=$(date +%Y-%m-%d)

# Função para extrair dados do CSV
extract_csv() {
    set -e  # Para o script em caso de erro
    cd "$PROJECT_PATH" || { echo "Falha ao acessar $PROJECT_PATH"; exit 1; }
    meltano elt tap-csv target-csv-csv
}

# Chama a função
extract_csv