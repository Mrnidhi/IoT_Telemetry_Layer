{{
  config(
    materialized='table',
    tags=['semantic_layer', 'device_health']
  )
}}

WITH heartbeat_base AS (
    SELECT
        device_id,
        heartbeat_timestamp,
        signal_strength_dbm,
        battery_percent,
        gps_accuracy_meters,
        device_temperature_c,
        is_online,
        ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY heartbeat_timestamp DESC) as recency_rank
    FROM {{ ref('stg_sensor_heartbeats') }}
),

latest_heartbeat AS (
    SELECT * FROM heartbeat_base WHERE recency_rank = 1
),

device_health_stats AS (
    SELECT
        d.device_id,
        d.device_model,
        d.fleet_id,
        d.is_active,
        lh.heartbeat_timestamp as last_heartbeat_time,
        lh.signal_strength_dbm as current_signal_strength,
        lh.battery_percent as current_battery_percent,
        lh.gps_accuracy_meters,
        lh.device_temperature_c,
        lh.is_online as current_status_online,
        DATEDIFF(MINUTE, lh.heartbeat_timestamp, CURRENT_TIMESTAMP()) as minutes_since_heartbeat,
        CASE 
            WHEN lh.battery_percent < 10 THEN 'CRITICAL'
            WHEN lh.battery_percent < 25 THEN 'WARNING'
            WHEN lh.is_online = FALSE THEN 'OFFLINE'
            WHEN lh.device_temperature_c > 60 THEN 'OVERHEATING'
            ELSE 'HEALTHY'
        END as health_status,
        AVG(hb.battery_percent) OVER (PARTITION BY d.device_id ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) as avg_battery_last_100,
        MIN(hb.battery_percent) OVER (PARTITION BY d.device_id ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) as min_battery_last_100
    FROM {{ ref('stg_devices') }} d
    LEFT JOIN latest_heartbeat lh ON d.device_id = lh.device_id
    LEFT JOIN {{ ref('stg_sensor_heartbeats') }} hb ON d.device_id = hb.device_id
)

SELECT
    device_id,
    device_model,
    fleet_id,
    is_active,
    last_heartbeat_time,
    current_signal_strength,
    current_battery_percent,
    gps_accuracy_meters,
    device_temperature_c,
    current_status_online,
    minutes_since_heartbeat,
    health_status,
    CASE 
        WHEN minutes_since_heartbeat > {{ var('device_offline_threshold_minutes') }} AND is_active THEN 1
        ELSE 0
    END as is_offline_anomaly,
    avg_battery_last_100,
    min_battery_last_100,
    ROUND((avg_battery_last_100 - current_battery_percent) / NULLIF(avg_battery_last_100, 0) * 100, 2) as battery_drain_rate_percent,
    CURRENT_TIMESTAMP() as created_at
FROM device_health_stats
WHERE is_active = TRUE
