Our Product Data Ingestion Pipeline involves several components:

- **AWS DMS**: We use [AWS DMS](https://aws.amazon.com/dms/features/) as a Change Data Capture engine. DMS is configured to read the production application databases' transaction logs for change-data events. These events are captured and can be sent to a variety of targets. In our configuration, DMS sends these CDC messages in parquet format to S3.
    
- **AWS S3 Bucket**: AWS DMS emits batches of CDC messages to S3
    - Files are stored in parquet format
    - bucket is partitioned by `source_database/source_table/yyyy/mm/dd/hh` for performance
    
- **dbt Ingestion Process**: The ingestion of the CDC messages into Snowflake and subsequent transformation of the data into analytics-ready views is driven by dbt.

- **Data Masking**: We utilize Snowflake's [Tag Based Masking](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies) to mask PHI and PII. Tags are applied to views, masking policies are applied to the raw data based on the value of the tag, and finally those views are shared out to the Enterprise account.
    
    [Product Data Ingestion - Data Governance - Tag Based Masking](https://www.notion.so/Product-Data-Ingestion-Data-Governance-Tag-Based-Masking-f70882c02af64b94bb5c9d5bf7560316?pvs=21)
    
- **Data Sharing**: The views are shared to the Standard Snowflake Account utilizing Snowflake's [Secure Data Sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro) features

For more information visit our [High Level Architecture page on Notion](https://www.notion.so/simplepractice/Product-Data-Ingestion-Technical-High-Level-Architecture-1abf2f8242f180edb541e5dc830d7c82)