# iSuite Configuration Files
# =============================
# This directory contains configuration files for iSuite services and features.

# Directory Structure:
# - config/                    # Main configuration directory
#   - ai/                      # AI/LLM service configurations
#   - robustness/              # Robustness service configurations
#   - build/                   # Build optimization configurations
#   - services/                # Service-specific configurations
#   - environments/            # Environment-specific overrides

# Configuration files are loaded in the following order:
# 1. Base configurations (built into services)
# 2. Environment-specific overrides
# 3. Local overrides (for development)

# All configurations support hot-reloading without app restart.
