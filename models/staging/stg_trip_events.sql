{{
  config(
    materialized='view',
    tags=['staging', 'trip_data']
  )
}}

SELECT
    trip_id,
    device_id,
    driver_id,
    CONVERT_TIMEZONE('UTC', trip_start_time) as trip_start_time,
    CONVERT_TIMEZONE('UTC', trip_end_time) as trip_end_time,
    distance_km,
    DATEDIFF(SECOND, trip_start_time, trip_end_time) as duration_seconds,
    ROUND(distance_km / NULLIF(DATEDIFF(HOUR, trip_start_time, trip_end_time), 0), 2) as avg_speed_kmh,
    max_speed_kmh,
    harsh_brakes_count,
    harsh_accelerations_count,
    route_polyline,
    CURRENT_TIMESTAMP() as _dbt_loaded_at
FROM raw.trips
WHERE trip_start_time >= DATEADD(DAY, -90, CURRENT_DATE())
  AND trip_id IS NOT NULL
  AND device_id IS NOT NULL
