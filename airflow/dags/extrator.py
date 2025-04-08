from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

default_args = {
    "owner": "gnobisP",
    "start_date": datetime(2024, 1, 1),
    "retries": 2
}

with DAG(
    "pipeline_dados_indicium",
    default_args=default_args,
    schedule="@daily",
    catchup=False,  
    description="Pipeline para extrair dados do Northwind e de um arquivo csv local e salva em um BD Postgres Warehouse",
    tags=["northwind", "elt"],
) as dag:

    extract_csv = BashOperator( 
        task_id="extract_csv",
        bash_command="script/extratorCSV.sh",
    )

    extract_postgres = BashOperator( 
        task_id="extract_postgres",
        bash_command="script/extratorPOSTGRE.sh",
    )

    fase2 = BashOperator(
        task_id="fase2",
        bash_command="script/fase2.sh",
    )

    # Executar extrações em paralelo
    [extract_csv, extract_postgres] >> fase2
