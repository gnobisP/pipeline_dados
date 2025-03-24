# <img src="https://github.com/jghoman/awesome-apache-airflow/raw/master/airflow-logo.png" alt="Meltano Logo" width="150" style="vertical-align: middle; margin-right: 20px"/> INFORMAÇÕES E AJUSTES DA FERRAMENTA

## 🔧 AJUSTES
- Nenhum ajuste é necessário 😃

## 🚨 Partes importante do meltano.yml

### meltano elt tap-csv target-csv-csv:
- tap-csv: extrai os dados da pasta "data/order_details.csv"
- target-csv-csv: Salva os dados do processo anterior em data/csv/{YY:mm:dd HH} em formato csv

### meltano elt tap-postgres target-postgres-csv:

- tap-csv: extrai os dados do servidor "nortwind"
- target-postgres-csv: Salva os dados do processo anterior em data/postgres/{table-name}/{YY:mm:dd HH}

### meltano elt tap-csv-fase2 target-postgres:
- realiza a extração das pastas criadas nos passos anteriores

- Caso queira especificar o tipo de dados para salvar no banco de dados do POSTGRE na fase2 realize o seguinte esquema, dessa forma os 'type' de dados são formatados quando inseridos no banco de dados warehouse postgres:

```sh
    - name: tap-csv-fase2
      inherit_from: tap-csv
      config:
        files:
          - entity: products
            path: ../data/postgres/public-products/$DATE/file.csv
            keys: ["product_id"]
            format: csv
            schema:  # Adicione esta seção
              properties:
                product_id:
                  type: integer

```


