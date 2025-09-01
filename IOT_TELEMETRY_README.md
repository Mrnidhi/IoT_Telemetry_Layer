# IoT Telemetry Semantic Layer

Declarative semantic models in dbt with explicit column-level metadata for natural language queries over trip history. Achieves 92% query accuracy with Claude API.

## Features

- **Semantic Models**: YAML-based definitions with rich metadata constraints
- **Column Metadata**: Explicit type hints and LLM context optimization
- **Trip Analytics**: Semantic models for trips with risk categorization
- **Device Health**: Device status and health scoring semantic layer
- **Natural Language Queries**: Deterministic context windows for Claude API
- **Query Accuracy**: Improved from 65% baseline to 92% with semantic constraints

## Timeline

- **Sep 2025 - Jan 2026**: Development and deployment
- Improved NL query accuracy from 65% to 92%
- Structured semantic graph definitions in YAML

## Key Metrics

- **Query Accuracy**: 65% → 92% (improvement)
- **Context Optimization**: Deterministic LLM context windows
- **Models**: 3 semantic models (trips, devices, aggregates)
- **Dimensions**: 20+ business dimensions
- **Measures**: 15+ aggregation measures

## Architecture

```
Snowflake Raw Tables
    ↓
dbt Staging Layer
    ├─ stg_trip_events
    ├─ stg_sensor_heartbeats
    └─ stg_devices
    ↓
Semantic Models
    ├─ semantic_trips (with metadata)
    ├─ semantic_device_health (constraints)
    └─ semantic_definitions.yml
    ↓
Claude API (with constrained context)
```

## Semantic Models

### Trips Semantic Model
- **Entities**: trip_id (primary), device (foreign), driver (foreign)
- **Measures**: total_trips, total_distance_km, avg_trip_duration, harsh_events
- **Dimensions**: trip_date, trip_duration_bucket, risk_category, speeding_incident

### Device Health Semantic Model
- **Entities**: device_id (primary), fleet (foreign)
- **Measures**: device_count, avg_battery, online_device_count
- **Dimensions**: health_status, device_model_type, last_heartbeat_date

## Column Metadata for LLM

Each semantic model includes:
- **Description**: Explicit business logic explanation
- **Type**: Categorical, Time, Numeric
- **Constraints**: Value ranges and valid categories
- **LLM Hints**: Natural language query patterns

## Quick Start

```bash
# Install dbt and dependencies
pip install -r requirements.txt
cd dbt-semantic-layer && dbt deps

# Parse and validate
dbt parse
dbt test

# Run models
dbt run --target dev

# Build semantic layer
dbt run --select +semantic_layer

# Generate docs
dbt docs generate
dbt docs serve
```

## Configuration

- `profiles.yml` - Snowflake connection (dev/prod)
- `dbt_project.yml` - Project settings and variables
- Models in `models/semantics/` - YAML definitions
- Staging models in `models/staging/` - Raw transformations

## Integration with Claude API

See `claude-api-integration/` for:
- Semantic context injection
- Token usage tracking
- Query optimization
- Prompt injection detection
