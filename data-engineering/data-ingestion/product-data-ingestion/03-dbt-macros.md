In the simplepractice-cdc-dbt project, we need to create multiple models for each source table. To optimize this process and reduce manual effort, we’ve created several custom dbt macros which dynamically generate the SQL for these models during runtime. This approach allows us to define most of our models of a specific type uniformly simply by invoking the corresponding macro.

test

For more information visit our [simplepractice-cdc-dbt dbt Macros page on Notion](https://www.notion.so/simplepractice/Product-Data-Ingestion-What-is-AWS-DMS-Why-AWS-DMS-8fc9be0f9f634f298c46589650ab16a9)