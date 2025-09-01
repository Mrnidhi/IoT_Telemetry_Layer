{{
  config(
    materialized='table',
    tags=['semantic_layer', 'trip_analytics']
  )
}}

WITH trip_base AS (
    SELECT
        t.trip_id,
        t.device_id,
        t.driver_id,
        d.device_model,
        d.fleet_id,
        t.trip_start_time,
        t.trip_end_time,
        t.distance_km,
        t.duration_seconds,
        t.avg_speed_kmh,
        t.max_speed_kmh,
        t.harsh_brakes_count,
        t.harsh_accelerations_count,
        CASE 
            WHEN t.harsh_brakes_count + t.harsh_accelerations_count > 10 THEN 'HIGH'
            WHEN t.harsh_brakes_count + t.harsh_accelerations_count > 5 THEN 'MEDIUM'
            ELSE 'LOW'
        END as risk_category,
        CASE WHEN t.max_speed_kmh > 120 THEN TRUE ELSE FALSE END as exceeds_speed_limit
    FROM {{ ref('stg_trip_events') }} t
    LEFT JOIN {{ ref('stg_devices') }} d ON t.device_id = d.device_id
),

trip_with_lag AS (
    SELECT
        *,
        LAG(trip_end_time) OVER (PARTITION BY driver_id ORDER BY trip_start_time) as prev_trip_end,
        ROW_NUMBER() OVER (PARTITION BY driver_id ORDER BY trip_start_time) as trip_sequence,
        DATEDIFF(MINUTE, LAG(trip_end_time) OVER (PARTITION BY driver_id ORDER BY trip_start_time), trip_start_time) as minutes_since_last_trip
    FROM trip_base
)

SELECT
    trip_id,
    device_id,
    driver_id,
    device_model,
    fleet_id,
    trip_start_time,
    trip_end_time,
    distance_km,
    duration_seconds,
    ROUND(duration_seconds / 60.0, 2) as duration_minutes,
    avg_speed_kmh,
    max_speed_kmh,
    harsh_brakes_count,
    harsh_accelerations_count,
    harsh_brakes_count + harsh_accelerations_count as total_harsh_events,
    risk_category,
    exceeds_speed_limit,
    trip_sequence,
    minutes_since_last_trip,
    CASE 
        WHEN risk_category = 'HIGH' OR exceeds_speed_limit THEN 1
        ELSE 0
    END as is_risky_trip,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at
FROM trip_with_lag
ORDER BY trip_start_time DESC
