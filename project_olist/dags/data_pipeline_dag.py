import io
import logging
import os
import shutil
from datetime import datetime, timedelta
from pathlib import Path
import pandas as pd
from airflow.decorators import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook

logger = logging.getLogger(__name__)

DATASET_NAME = "olistbr/brazilian-ecommerce"
BASE_DIR = Path("/tmp/olist_data")

FILE_TABLE_MAPPING = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "product_category_name_translation",
}

@dag(
    dag_id="olist_kaggle_etl",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["etl", "kaggle", "ecommerce", "raw"],
    default_args={
        "retries": 1,
        "retry_delay": timedelta(seconds=30),
    },
)
def olist_kaggle_etl():

    @task()
    def download_kaggle_dataset() -> str:
        from kaggle.api.kaggle_api_extended import KaggleApi
        BASE_DIR.mkdir(parents=True, exist_ok=True)
        api = KaggleApi()
        api.authenticate()
        logger.info("Скачивание датасета %s из Kaggle...", DATASET_NAME)
        api.dataset_download_files(DATASET_NAME, path=str(BASE_DIR), unzip=True)
        return str(BASE_DIR)

    @task()
    def truncate_raw_tables() -> None:
        hook = PostgresHook(postgres_conn_id="postgres_olist")
        tables = ", ".join([f"raw.{tbl}" for tbl in FILE_TABLE_MAPPING.values()])
        hook.run(f"TRUNCATE TABLE {tables} CASCADE;")

    @task()
    def load_table(filename: str, table_name: str) -> None:
        file_path = BASE_DIR / filename
        if not file_path.exists():
            logger.warning("Файл не найден: %s", file_path)
            return
        df = pd.read_csv(file_path)
        buffer = io.StringIO()
        df.to_csv(buffer, index=False, na_rep="\\N")
        buffer.seek(0)
        hook = PostgresHook(postgres_conn_id="postgres_olist")
        with hook.get_conn() as conn:
            with conn.cursor() as cur:
                cur.copy_expert(
                    f"COPY raw.{table_name} FROM STDIN WITH CSV HEADER NULL '\\N'",
                    buffer,
                )
            conn.commit()
        logger.info("Таблица raw.%s: загружено %d строк", table_name, len(df))

    @task(trigger_rule="all_done")
    def cleanup_temp_files() -> None:
        if BASE_DIR.exists():
            shutil.rmtree(BASE_DIR)

    downloaded = download_kaggle_dataset()
    truncated = truncate_raw_tables()

    load_tasks = []
    for filename, table in FILE_TABLE_MAPPING.items():
        task_node = load_table.override(task_id=f"load_{table}")(filename, table)
        load_tasks.append(task_node)

    downloaded >> load_tasks
    truncated >> load_tasks
    load_tasks >> cleanup_temp_files()


dag_instance = olist_kaggle_etl()