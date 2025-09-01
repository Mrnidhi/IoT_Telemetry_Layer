{{
  config(
    materialized='view',
    tags=['staging', 'device_master']
  )
}}

SELECT
    device_id,
    device_model,
    firmware_version,
    fleet_id,
    installation_date,
    is_active,
    CURRENT_TIMESTAMP() as _dbt_loaded_at
FROM raw.devices
WHERE is_deleted = FALSE
