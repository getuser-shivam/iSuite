# iSuite Configuration Examples
# ==============================
#
# This file contains example configurations for different environments and use cases.
# Copy and modify these configurations for your specific deployment needs.
#
# Configuration files should be placed in: config/environments/
# Use CentralConfig to load them based on your environment.

# =============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/development.yaml
# Purpose: Local development with enhanced debugging and relaxed constraints

environment: development

# Core Application Settings
app:
  name: "iSuite Development"
  version: "2.0.0-dev"
  debug: true
  environment: "development"

# Logging Configuration - Verbose logging for debugging
logging:
  level: debug
  file_output: true
  console_output: true
  rotation: daily
  max_file_size: 10MB
  retention_days: 7
  performance_tracking: true

# UI Configuration - Enhanced for development
ui:
  primary_color: 0xFF2196F3
  theme_mode: system
  animation_duration_fast: 300  # Slower for debugging
  animation_duration_medium: 500
  border_radius_medium: 16  # More rounded for modern look
  enable_debug_banners: true

# Supabase Configuration - Local/development instance
supabase:
  url: "https://your-dev-project.supabase.co"
  anon_key: "your-development-anon-key"
  connection_timeout: 30
  auth:
    auto_refresh_token: true
    persist_session: true
    debug_logging: true
  realtime:
    enabled: true
    debug_logging: true

# PocketBase Configuration - Local development server
pocketbase:
  url: "http://localhost:8090"
  email: "admin@dev.local"
  password: "development-password"
  collections:
    - posts
    - users
    - files
  realtime_enabled: true
  debug_mode: true

# Robustness Configuration - Relaxed for development
robustness:
  circuit_breaker_enabled: false  # Disabled for easier debugging
  health_check_interval: 30       # More frequent checks
  retry_max_attempts: 2           # Fewer retries for faster feedback
  error_reporting_enabled: true
  debug_mode: true

# Performance Configuration - Monitoring enabled
performance:
  monitoring_enabled: true
  memory_tracking: true
  cpu_tracking: true
  network_tracking: true
  cache_enabled: false  # Disabled for debugging
  optimization_level: none

# Security Configuration - Relaxed for development
security:
  encryption_enabled: false  # Disabled for easier debugging
  audit_logging: true
  input_validation_strict: false
  rate_limiting_enabled: false

# Cache Configuration - Disabled for development
cache:
  enabled: false
  ttl_minutes: 5
  max_entries: 100

# Analytics Configuration - Disabled for development
analytics:
  enabled: false
  privacy_compliant: true

# Build Configuration - Debug focused
build:
  optimization_level: none
  obfuscation: false
  tree_shaking: false
  source_maps: true

# =============================================================================
# STAGING ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/staging.yaml
# Purpose: Pre-production testing with production-like settings

environment: staging

app:
  name: "iSuite Staging"
  version: "2.0.0-staging"
  debug: false
  environment: "staging"

logging:
  level: info
  file_output: true
  console_output: true
  rotation: daily
  max_file_size: 50MB
  retention_days: 30
  performance_tracking: true

supabase:
  url: "https://your-staging-project.supabase.co"
  anon_key: "your-staging-anon-key"
  connection_timeout: 45
  auth:
    auto_refresh_token: true
    persist_session: true
  realtime:
    enabled: true

pocketbase:
  url: "https://staging-api.isuite.com"
  email: "admin@staging.isuite.com"
  password: "${POCKETBASE_STAGING_PASSWORD}"  # Environment variable
  collections:
    - posts
    - users
    - files
  realtime_enabled: true

robustness:
  circuit_breaker_enabled: true
  health_check_interval: 60
  retry_max_attempts: 3
  error_reporting_enabled: true
  debug_mode: false

performance:
  monitoring_enabled: true
  memory_tracking: true
  cpu_tracking: true
  network_tracking: true
  cache_enabled: true
  optimization_level: medium

security:
  encryption_enabled: true
  audit_logging: true
  input_validation_strict: true
  rate_limiting_enabled: true

cache:
  enabled: true
  ttl_minutes: 30
  max_entries: 1000

analytics:
  enabled: true
  privacy_compliant: true
  test_mode: true

# =============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/production.yaml
# Purpose: Live production environment with maximum security and performance

environment: production

app:
  name: "iSuite Pro"
  version: "2.0.0"
  debug: false
  environment: "production"

logging:
  level: warning
  file_output: true
  console_output: false
  rotation: daily
  max_file_size: 100MB
  retention_days: 90
  performance_tracking: true
  remote_logging: true
  log_server_url: "https://logs.isuite.com/api/logs"

supabase:
  url: "https://your-prod-project.supabase.co"
  anon_key: "your-production-anon-key"
  connection_timeout: 60
  auth:
    auto_refresh_token: true
    persist_session: true
    session_timeout_hours: 24
  realtime:
    enabled: true
    connection_pool_size: 10
  security:
    ssl_verification: true
    certificate_pinning: true

pocketbase:
  url: "https://api.isuite.com"
  email: "admin@isuite.com"
  password: "${POCKETBASE_PROD_PASSWORD}"
  collections:
    - posts
    - users
    - files
    - analytics
    - backups
  realtime_enabled: true
  backup_enabled: true
  backup_interval_hours: 24

robustness:
  circuit_breaker_enabled: true
  health_check_interval: 120
  retry_max_attempts: 5
  error_reporting_enabled: true
  debug_mode: false
  graceful_shutdown_timeout: 300
  auto_recovery_enabled: true

performance:
  monitoring_enabled: true
  memory_tracking: true
  cpu_tracking: true
  network_tracking: true
  cache_enabled: true
  optimization_level: maximum
  compression_enabled: true
  lazy_loading_enabled: true

security:
  encryption_enabled: true
  audit_logging: true
  input_validation_strict: true
  rate_limiting_enabled: true
  brute_force_protection: true
  session_management: strict
  data_masking: true
  compliance_mode: gdpr

cache:
  enabled: true
  ttl_minutes: 60
  max_entries: 10000
  compression: true
  distributed_cache: true
  redis_url: "${REDIS_URL}"

analytics:
  enabled: true
  privacy_compliant: true
  data_retention_days: 365
  anonymization: true
  export_enabled: true

# =============================================================================
# ENTERPRISE ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/enterprise.yaml
# Purpose: Large-scale enterprise deployment with advanced features

environment: enterprise

app:
  name: "iSuite Enterprise"
  version: "2.0.0-enterprise"
  debug: false
  environment: "enterprise"
  multi_tenant: true
  user_limits: 10000

logging:
  level: warning
  file_output: true
  console_output: false
  rotation: hourly
  max_file_size: 500MB
  retention_days: 365
  performance_tracking: true
  remote_logging: true
  log_server_url: "https://enterprise-logs.isuite.com/api/logs"
  log_aggregation: true

supabase:
  url: "https://enterprise-db.isuite.com"
  anon_key: "${SUPABASE_ENTERPRISE_ANON_KEY}"
  connection_timeout: 120
  auth:
    auto_refresh_token: true
    persist_session: true
    session_timeout_hours: 8  # Shorter for security
    mfa_required: true
    sso_enabled: true
  realtime:
    enabled: true
    connection_pool_size: 50
    load_balancing: true
  database:
    connection_pool_size: 20
    read_replicas: true
    backup_schedule: "daily"

pocketbase:
  url: "https://enterprise-api.isuite.com"
  email: "admin@enterprise.isuite.com"
  password: "${POCKETBASE_ENTERPRISE_PASSWORD}"
  collections:
    - posts
    - users
    - files
    - analytics
    - backups
    - audit_logs
    - organizations
    - teams
  realtime_enabled: true
  backup_enabled: true
  backup_interval_hours: 6
  multi_tenant: true

robustness:
  circuit_breaker_enabled: true
  health_check_interval: 300
  retry_max_attempts: 5
  error_reporting_enabled: true
  debug_mode: false
  graceful_shutdown_timeout: 600
  auto_recovery_enabled: true
  load_balancing_enabled: true
  failover_enabled: true

performance:
  monitoring_enabled: true
  memory_tracking: true
  cpu_tracking: true
  network_tracking: true
  cache_enabled: true
  optimization_level: maximum
  compression_enabled: true
  lazy_loading_enabled: true
  cdn_enabled: true
  edge_computing: true

security:
  encryption_enabled: true
  audit_logging: true
  input_validation_strict: true
  rate_limiting_enabled: true
  brute_force_protection: true
  session_management: strict
  data_masking: true
  compliance_mode: soc2
  encryption_level: fips_140_2
  zero_trust: true

cache:
  enabled: true
  ttl_minutes: 120
  max_entries: 100000
  compression: true
  distributed_cache: true
  redis_cluster: true
  redis_url: "${REDIS_CLUSTER_URL}"

analytics:
  enabled: true
  privacy_compliant: true
  data_retention_days: 2555  # 7 years
  anonymization: true
  export_enabled: true
  advanced_analytics: true
  predictive_modeling: true
  business_intelligence: true

# =============================================================================
# CI/CD ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/ci.yaml
# Purpose: Continuous Integration/Deployment environment

environment: ci

app:
  name: "iSuite CI"
  version: "${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA:-ci-build}}"
  debug: true
  environment: "ci"

logging:
  level: info
  file_output: true
  console_output: true
  rotation: none
  performance_tracking: true

supabase:
  url: "https://ci-db.isuite.com"
  anon_key: "${SUPABASE_CI_ANON_KEY}"
  connection_timeout: 30

pocketbase:
  url: "http://localhost:8090"
  email: "ci@isuite.com"
  password: "ci-password"

robustness:
  circuit_breaker_enabled: false
  health_check_interval: 10
  retry_max_attempts: 1

performance:
  monitoring_enabled: true
  cache_enabled: false

security:
  encryption_enabled: false
  audit_logging: false

testing:
  enabled: true
  unit_tests: true
  integration_tests: true
  ui_tests: true
  performance_tests: true
  coverage_required: 80
  test_timeout_minutes: 30

build:
  optimization_level: high
  obfuscation: true
  tree_shaking: true
  source_maps: false
  bundle_analyzer: true

# =============================================================================
# DOCKER ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/docker.yaml
# Purpose: Containerized deployment configuration

environment: docker

app:
  name: "iSuite Docker"
  version: "2.0.0-docker"
  debug: false
  environment: "docker"
  containerized: true

logging:
  level: info
  file_output: true
  console_output: true
  rotation: daily
  log_driver: json-file
  log_max_size: 10m
  log_max_files: 3

supabase:
  url: "${SUPABASE_URL}"
  anon_key: "${SUPABASE_ANON_KEY}"
  connection_timeout: 60

pocketbase:
  url: "${POCKETBASE_URL:-http://pocketbase:8090}"
  email: "${POCKETBASE_EMAIL}"
  password: "${POCKETBASE_PASSWORD}"

robustness:
  circuit_breaker_enabled: true
  health_check_interval: 60
  retry_max_attempts: 3
  container_health_checks: true

performance:
  monitoring_enabled: true
  memory_limit_mb: 512
  cpu_limit_cores: 1.0
  cache_enabled: true

security:
  encryption_enabled: true
  secret_management: docker_secrets

# Docker-specific settings
docker:
  health_check_endpoint: "/health"
  readiness_probe: "/ready"
  liveness_probe: "/live"
  graceful_shutdown_seconds: 30
  resource_limits:
    memory: "512m"
    cpu: "1000m"

# =============================================================================
# MOBILE-ONLY ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/mobile.yaml
# Purpose: Mobile-specific optimizations and features

environment: mobile

app:
  name: "iSuite Mobile"
  version: "2.0.0-mobile"
  platform: mobile
  form_factor: phone_tablet

ui:
  adaptive_layout: true
  touch_optimized: true
  gesture_navigation: true
  haptic_feedback: true
  dark_mode_system: true

# Mobile-specific optimizations
mobile:
  battery_optimization: true
  offline_first: true
  background_sync: true
  push_notifications: true
  biometric_auth: true
  camera_integration: true
  file_sharing: true
  app_shortcuts: true

performance:
  memory_optimization: aggressive
  image_compression: true
  lazy_loading: true
  background_processing: limited

# Platform-specific features
platform_features:
  android:
    intent_filters: true
    app_shortcuts: true
    widgets: true
    autofill: true
  ios:
    handoff: true
    siri_shortcuts: true
    app_extensions: true
    universal_links: true

# =============================================================================
# OFFLINE-ONLY ENVIRONMENT CONFIGURATION
# =============================================================================
# File: config/environments/offline.yaml
# Purpose: Offline-first configuration for limited connectivity

environment: offline

app:
  name: "iSuite Offline"
  version: "2.0.0-offline"
  offline_first: true

# Offline-specific features
offline:
  sync_enabled: true
  local_storage_priority: true
  conflict_resolution: manual
  background_sync: true
  data_compression: true
  cache_strategy: aggressive

cache:
  enabled: true
  ttl_minutes: 1440  # 24 hours
  max_entries: 50000
  offline_cache: true
  prefetch_enabled: true

robustness:
  circuit_breaker_enabled: true
  offline_mode_detection: true
  retry_offline_operations: true
  data_persistence: guaranteed

# Limited network features
network:
  timeout_seconds: 10
  retry_attempts: 1
  background_sync_only: true
  wifi_only_sync: true

# =============================================================================
# CONFIGURATION TEMPLATES
# =============================================================================
# File: config/templates/service_template.yaml
# Purpose: Template for adding new services

service_template:
  name: "NewService"
  version: "1.0.0"
  enabled: true
  dependencies: []
  parameters:
    # Service-specific parameters
    service.enabled: true
    service.debug: false
    service.timeout: 30
    service.retry_count: 3
    service.cache_enabled: true
    service.monitoring_enabled: true

# File: config/templates/feature_flag_template.yaml
# Purpose: Template for feature flags

feature_flags:
  new_feature_enabled: false
  experimental_ui: false
  advanced_analytics: true
  beta_features: false
  premium_features: true

# =============================================================================
# ENVIRONMENT VARIABLE MAPPING
# =============================================================================
# File: config/environment_variables.yaml
# Purpose: Mapping of configuration to environment variables

environment_variables:
  # Database
  SUPABASE_URL: supabase.url
  SUPABASE_ANON_KEY: supabase.anon_key
  POCKETBASE_URL: pocketbase.url
  POCKETBASE_PASSWORD: pocketbase.password

  # Security
  ENCRYPTION_KEY: security.encryption_key
  JWT_SECRET: security.jwt_secret

  # External Services
  REDIS_URL: cache.redis_url
  LOG_SERVER_URL: logging.remote_url

  # Feature Flags
  ENABLE_ANALYTICS: analytics.enabled
  DEBUG_MODE: app.debug

# =============================================================================
# CONFIGURATION VALIDATION RULES
# =============================================================================
# File: config/validation_rules.yaml
# Purpose: Validation rules for configuration parameters

validation_rules:
  supabase.url:
    required: true
    pattern: "^https://[a-zA-Z0-9.-]+\\.supabase\\.co$"

  supabase.anon_key:
    required: true
    min_length: 100

  robustness.retry_max_attempts:
    type: integer
    min: 0
    max: 10

  performance.cache_ttl_minutes:
    type: integer
    min: 1
    max: 1440

  security.encryption_key:
    required_when: "security.encryption_enabled"
    min_length: 32

# =============================================================================
# CONFIGURATION MIGRATION SCRIPTS
# =============================================================================
# File: config/migrations/v2.0.0_migration.yaml
# Purpose: Migration guide for version upgrades

migration_v2_0_0:
  description: "Migration from v1.x to v2.0.0"
  breaking_changes:
    - "Supabase configuration now requires service_role_key for admin operations"
    - "Robustness services are now enabled by default"
    - "UI theme configuration moved to ui.theme namespace"

  migration_steps:
    1: "Update supabase.service_role_key in configuration"
    2: "Review robustness settings for your environment"
    3: "Update UI theme references to new namespace"
    4: "Run configuration validation: python validate_config.py"

  rollback_plan:
    - "Keep v1.x configuration as backup"
    - "Gradual rollout with feature flags"
    - "Automated rollback scripts available"

# =============================================================================
# END OF CONFIGURATION EXAMPLES
# =============================================================================

# Notes:
# - Use ${VARIABLE_NAME} syntax for environment variables
# - All paths should be relative to project root
# - Boolean values: true/false
# - Numeric values: integers or floats as needed
# - Color values: 0xFFRRGGBB format for Flutter
# - Duration values: in seconds unless specified otherwise
#
# Copy these configurations to your config/environments/ directory
# and modify them according to your specific requirements.
