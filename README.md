# Аналитические пет-проекты (ETL, SQL, Python, BI)

В репозитории два проекта на открытых данных с Kaggle. Стек развернут локально в Docker: Airflow для оркестрации, PostgreSQL в качестве хранилища, витрины на SQL, исследовательский анализ в Python и дашборды в Superset и PowerBI.

## Структура

* **[project_bike_store](./project_bike_store)** — выгрузка реляционной базы веломагазина в PostgreSQL, написание SQL-витрин и сборка дашборда в Apache Superset.
* **[project_olist](./project_olist)** — быстрый ETL через `COPY` в Postgres для 100k+ строк e-commerce, когортный анализ, RFM, проверка гипотез о влиянии логистики на рейтинг в Jupyter и отчет в PowerBI.

## Стек технологий

* **Базы данных и ETL:** PostgreSQL, Apache Airflow, Docker Compose
* **Анализ данных:** Python (Pandas, NumPy, SciPy, Matplotlib, Seaborn)
* **BI:** Apache Superset, PowerBI