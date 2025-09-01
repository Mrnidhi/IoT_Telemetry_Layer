{{
  config(
    materialized='view',
    tags=['staging', 'sensor_data']
  )
}}

SELECT
    heartbeat_id,
    device_id,
    CONVERT_TIMEZONE('UTC', heartbeat_timestamp) as heartbeat_timestamp,
    signal_strength_dbm,
    battery_percent,
    gps_accuracy_meters,
    device_temperature_c,
    CASE WHEN heartbeat_timestamp >= DATEADD(MINUTE, -{{ var('device_offline_threshold_minutes') }}, CURRENT_TIMESTAMP())
         THEN TRUE
         ELSE FALSE
    END as is_online,
    CURRENT_TIMESTAMP() as _dbt_loaded_at
FROM raw.sensor_heartbeats
WHERE heartbeat_timestamp >= DATEADD(DAY, -30, CURRENT_DATE())
  AND device_id IS NOT NULL
