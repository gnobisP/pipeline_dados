import os
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

script_path_csv = os.path.join(os.path.dirname(__file__), "script", "extratorCSV.sh")
script_path_postgres = os.path.join(os.path.dirname(__file__), "script", "extratorPOSTGRE.sh")
script_path_segunda = os.path.join(os.path.dirname(__file__), "script", "fase2.sh")

default_args = {
    "owner": "gnobisP",
    "start_date": datetime(2024, 1, 1),
    "retries": 2
}

with DAG(
    "pipeline_dados_indicium",
    default_args=default_args,
    schedule="@daily",
    catchup=True,  #Permitir datas anteriores
    description="Pipeline para extrair dados do Northwind e de um arquivo csv local e salva em um BD Postgres Warehouse",
    tags=["northwind", "elt"],
) as dag:

    extract_csv = BashOperator( 
        task_id="extract_csv",
        bash_command=f"bash {script_path_csv} '{{{{ ds }}}}'", 
    )

    extract_postgres = BashOperator( 
        task_id="extract_postgres",
        bash_command=f"bash {script_path_postgres} '{{{{ ds }}}}'", 
    )

    fase2 = BashOperator(
        task_id="fase2",
        bash_command=f"bash {script_path_segunda} '{{{{ ds }}}}'", 
    )

    # Executar extrações em paralelo
    [extract_csv, extract_postgres] >> fase2
