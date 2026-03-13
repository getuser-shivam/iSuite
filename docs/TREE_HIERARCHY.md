# iSuite Tree Hierarchy Guide

## 🌳 Project Tree Hierarchy

This document defines the **complete tree hierarchy** for the iSuite project, ensuring **proper organization, logical grouping, and clear relationships** between all components and files.

## 📁 Complete Directory Tree

```
iSuite/
├── 📄 README.md                           # Project overview and documentation
├── 📄 LICENSE                            # MIT License
├── 📄 pubspec.yaml                       # Flutter dependencies
├── 📄 analysis_options.yaml              # Dart analysis configuration
├── 📄 .gitignore                         # Git ignore rules
├── 📄 .git/                             # Git repository
│   ├── 📁 hooks/
│   │   ├── 📄 applypatch-msg.sample
│   │   ├── 📄 commit-msg.sample
│   │   ├── 📄 fsmonitor-watchman.sample
│   │   └── 📄 pre-commit.sample
│   ├── 📁 info/
│   │   ├── 📄 exclude
│   │   └── 📄 refs/
│   ├── 📁 logs/
│   │   ├── 📄 HEAD
│   │   └── 📄 refs/
│   ├── 📁 objects/
│   ├── 📄 COMMIT_EDITMSG
│   ├── 📄 HEAD
│   ├── 📄 config
│   ├── 📄 description
│   └── 📄 packed-refs
│
├── 📁 lib/                              # Main application source
│   ├── 📄 main.dart                     # Application entry point
│   ├── 📁 l10n/                         # Internationalization
│   │   ├── 📄 app_en.arb               # English translations
│   │   ├── 📄 app_es.arb               # Spanish translations
│   │   └── 📄 app_fr.arb               # French translations
│   ├── 📁 core/                         # Core business logic
│   │   ├── 📁 orchestrator/            # 🆕 Application orchestration
│   │   │   └── 📄 application_orchestrator.dart
│   │   ├── 📁 registry/                # 🆕 Service registry
│   │   │   └── 📄 service_registry.dart
│   │   ├── 📁 config/                   # Configuration layer
│   │   │   ├── 📄 central_parameterized_config.dart
│   │   │   ├── 📄 component_relationship_manager.dart
│   │   │   ├── 📄 unified_service_orchestrator.dart
│   │   │   └── 📄 parameterization_validation_suite.dart
│   │   ├── 📁 ai/                      # AI Services Layer
│   │   │   ├── 📄 ai_file_organizer.dart
│   │   │   ├── 📄 ai_advanced_search.dart
│   │   │   ├── 📄 smart_file_categorizer.dart
│   │   │   ├── 📄 ai_duplicate_detector.dart
│   │   │   ├── 📄 ai_file_recommendations.dart
│   │   │   └── 📄 ai_services_integration.dart
│   │   ├── 📁 network/                  # Network Services Layer
│   │   │   ├── 📄 enhanced_network_file_sharing.dart
│   │   │   ├── 📄 advanced_ftp_client.dart
│   │   │   ├── 📄 wifi_direct_p2p_service.dart
│   │   │   ├── 📄 webdav_client.dart
│   │   │   ├── 📄 network_discovery_service.dart
│   │   │   ├── 📄 network_security_service.dart
│   │   │   └── 📄 network_file_sharing_integration.dart
│   │   ├── 📁 backend/                  # Backend Services Layer
│   │   │   ├── 📄 enhanced_pocketbase_service.dart
│   │   │   └── 📄 enhanced_database_service.dart
│   │   ├── 📁 logging/                  # Logging Layer
│   │   │   └── 📄 enhanced_logger.dart
│   │   ├── 📁 performance/              # Performance Layer
│   │   │   └── 📄 enhanced_performance_manager.dart
│   │   ├── 📁 security/                 # Security Layer
│   │   │   └── 📄 enhanced_security_service.dart
│   │   └── 📁 utils/                    # Utility Layer
│   │       ├── 📄 constants.dart
│   │       ├── 📄 helpers.dart
│   │       └── 📄 extensions.dart
│   ├── 📁 data/                          # Data Layer
│   │   ├── 📄 index.dart                 # Data layer exports
│   │   ├── 📁 models/                   # Data Models
│   │   │   ├── 📄 user_model.dart
│   │   │   ├── 📄 file_model.dart
│   │   │   ├── 📄 network_model.dart
│   │   │   ├── 📄 ai_model.dart
│   │   │   ├── 📄 configuration_model.dart
│   │   │   └── 📄 service_model.dart
│   │   ├── 📁 repositories/             # Data Repositories
│   │   │   ├── 📄 user_repository.dart
│   │   │   ├── 📄 file_repository.dart
│   │   │   ├── 📄 network_repository.dart
│   │   │   ├── 📄 ai_repository.dart
│   │   │   ├── 📄 configuration_repository.dart
│   │   │   └── 📄 service_repository.dart
│   │   └── 📁 datasources/               # Data Sources
│   │       ├── 📄 local_datasource.dart
│   │       ├── 📄 remote_datasource.dart
│   │       ├── 📄 cache_datasource.dart
│   │       └── 📄 database_datasource.dart
│   ├── 📁 domain/                        # Domain Layer
│   │   ├── 📄 index.dart                 # Domain layer exports
│   │   ├── 📁 entities/                 # Domain Entities
│   │   │   ├── 📄 user.dart
│   │   │   ├── 📄 file.dart
│   │   │   ├── 📄 network.dart
│   │   │   ├── 📄 ai.dart
│   │   │   ├── 📄 configuration.dart
│   │   │   └── 📄 service.dart
│   │   ├── 📁 repositories/             # Domain Repositories
│   │   │   ├── 📄 user_repository_interface.dart
│   │   │   ├── 📄 file_repository_interface.dart
│   │   │   ├── 📄 network_repository_interface.dart
│   │   │   ├── 📄 ai_repository_interface.dart
│   │   │   ├── 📄 configuration_repository_interface.dart
│   │   │   └── 📄 service_repository_interface.dart
│   │   └── 📁 services/                 # Domain Services
│   │       ├── 📄 user_service.dart
│   │       ├── 📄 file_service.dart
│   │       ├── 📄 network_service.dart
│   │       ├── 📄 ai_service.dart
│   │       ├── 📄 configuration_service.dart
│   │       └── 📄 service_service.dart
│   └── 📁 presentation/                  # Presentation Layer
│       ├── 📄 enhanced_parameterized_app.dart
│       ├── 📁 screens/                   # App Screens
│       │   ├── 📄 home_screen.dart
│       │   ├── 📄 file_management_screen.dart
│       │   ├── 📄 network_sharing_screen.dart
│       │   ├── 📄 ai_features_screen.dart
│       │   ├── 📄 settings_screen.dart
│       │   ├── 📄 configuration_screen.dart
│       │   └── 📄 about_screen.dart
│       ├── 📁 widgets/                   # UI Widgets
│       │   ├── 📁 common/               # Common Widgets
│       │   │   ├── 📄 app_scaffold.dart
│       │   │   ├── 📄 app_bar.dart
│       │   │   ├── 📄 app_drawer.dart
│       │   │   ├── 📄 app_button.dart
│       │   │   └── 📄 app_dialog.dart
│       │   ├── 📁 file/                  # File Widgets
│       │   │   ├── 📄 file_list_widget.dart
│       │   │   ├── 📄 file_item_widget.dart
│       │   │   ├── 📄 file_preview_widget.dart
│       │   │   ├── 📄 file_operations_widget.dart
│       │   │   └── 📄 file_metadata_widget.dart
│       │   ├── 📁 network/               # Network Widgets
│       │   │   ├── 📄 device_list_widget.dart
│       │   │   ├── 📄 connection_widget.dart
│       │   │   ├── 📄 transfer_widget.dart
│       │   │   ├── 📄 service_status_widget.dart
│       │   │   └── 📄 network_settings_widget.dart
│       │   ├── 📁 ai/                    # AI Widgets
│       │   │   ├── 📄 ai_analyzer_widget.dart
│       │   │   ├── 📄 ai_search_widget.dart
│       │   │   ├── 📄 ai_recommendations_widget.dart
│       │   │   ├── 📄 ai_progress_widget.dart
│       │   │   └── 📄 ai_results_widget.dart
│       │   └── 📁 configuration/         # Configuration Widgets
│       │       ├── 📄 config_form_widget.dart
│       │       ├── 📄 config_item_widget.dart
│       │       ├── 📄 config_section_widget.dart
│       │       └── 📄 config_validation_widget.dart
│       ├── 📁 theme/                    # App Theme
│       │   ├── 📄 enhanced_app_theme.dart
│       │   ├── 📄 light_theme.dart
│       │   ├── 📄 dark_theme.dart
│       │   ├── 📄 high_contrast_theme.dart
│       │   └── 📄 theme_data.dart
│       └── 📁 providers/                # State Providers
│           ├── 📄 app_provider.dart
│           ├── 📄 config_provider.dart
│           ├── 📄 service_provider.dart
│           ├── 📄 user_provider.dart
│           └── 📄 file_provider.dart
│
├── 📁 config/                           # Configuration Files
│   ├── 📄 central_config.yaml         # Central configuration
│   ├── 📁 environments/                 # Environment configs
│   │   ├── 📄 development.yaml
│   │   ├── 📄 staging.yaml
│   │   └── 📄 production.yaml
│   ├── 📁 ai/                         # AI Configuration
│   │   └── 📄 ai_config.yaml
│   ├── 📁 network/                    # Network Configuration
│   │   └── 📄 network_config.yaml
│   ├── 📁 performance/                # Performance Configuration
│   │   └── 📄 performance_config.yaml
│   ├── 📁 security/                    # Security Configuration
│   │   └── 📄 security_config.yaml
│   ├── 📁 ui/                         # UI Configuration
│   │   └── 📄 ui_config.yaml
│   ├── 📁 backend/                    # Backend Configuration
│   │   └── 📄 backend_config.yaml
│   └── 📁 logging/                    # Logging Configuration
│       └── 📄 logging_config.yaml
│
├── 📁 test/                            # Test Files
│   ├── 📄 app_test.dart                 # Main app test
│   ├── 📁 unit/                       # Unit Tests
│   │   ├── 📁 core/
│   │   │   ├── 📁 ai/
│   │   │   │   ├── 📄 ai_file_organizer_test.dart
│   │   │   │   ├── 📄 ai_advanced_search_test.dart
│   │   │   │   ├── 📄 smart_file_categorizer_test.dart
│   │   │   │   ├── 📄 ai_duplicate_detector_test.dart
│   │   │   │   └── 📄 ai_file_recommendations_test.dart
│   │   │   ├── 📁 network/
│   │   │   │   ├── 📄 enhanced_network_file_sharing_test.dart
│   │   │   │   ├── 📄 advanced_ftp_client_test.dart
│   │   │   │   ├── 📄 wifi_direct_p2p_service_test.dart
│   │   │   │   ├── 📄 webdav_client_test.dart
│   │   │   │   ├── 📄 network_discovery_service_test.dart
│   │   │   │   └── 📄 network_security_service_test.dart
│   │   │   ├── 📁 config/
│   │   │   │   ├── 📄 central_parameterized_config_test.dart
│   │   │   │   ├── 📄 component_relationship_manager_test.dart
│   │   │   │   ├── 📄 unified_service_orchestrator_test.dart
│   │   │   │   └── 📄 parameterization_validation_suite_test.dart
│   │   │   ├── 📁 orchestrator/
│   │   │   │   └── 📄 application_orchestrator_test.dart
│   │   │   ├── 📁 registry/
│   │   │   │   └── 📄 service_registry_test.dart
│   │   │   └── 📁 logging/
│   │   │       └── 📄 enhanced_logger_test.dart
│   │   ├── 📁 data/
│   │   │   ├── 📁 models/
│   │   │   │   ├── 📄 user_model_test.dart
│   │   │   │   ├── 📄 file_model_test.dart
│   │   │   │   ├── 📄 network_model_test.dart
│   │   │   │   └── 📄 ai_model_test.dart
│   │   │   ├── 📁 repositories/
│   │   │   │   ├── 📄 user_repository_test.dart
│   │   │   │   ├── 📄 file_repository_test.dart
│   │   │   │   ├── 📄 network_repository_test.dart
│   │   │   │   └── 📄 ai_repository_test.dart
│   │   │   └── 📁 datasources/
│   │   │       ├── 📄 local_datasource_test.dart
│   │   │       ├── 📄 remote_datasource_test.dart
│   │   │       └── 📄 cache_datasource_test.dart
│   │   ├── 📁 domain/
│   │   │   ├── 📁 entities/
│   │   │   │   ├── 📄 user_test.dart
│   │   │   │   ├── 📄 file_test.dart
│   │   │   │   ├── 📄 network_test.dart
│   │   │   │   └── 📄 ai_test.dart
│   │   │   └── 📁 services/
│   │   │       ├── 📄 user_service_test.dart
│   │   │       ├── 📄 file_service_test.dart
│   │   │       ├── 📄 network_service_test.dart
│   │   │       └── 📄 ai_service_test.dart
│   │   └── 📁 presentation/
│   │       ├── 📁 screens/
│   │       │   ├── 📄 home_screen_test.dart
│   │       │   ├── 📄 file_management_screen_test.dart
│   │       │   ├── 📄 network_sharing_screen_test.dart
│   │       │   ├── 📄 ai_features_screen_test.dart
│   │       │   └── 📄 settings_screen_test.dart
│   │       └── 📁 widgets/
│   │           ├── 📁 common/
│   │           │   ├── 📄 app_scaffold_test.dart
│   │           │   ├── 📄 app_bar_test.dart
│   │           │   └── 📄 app_drawer_test.dart
│   │           ├── 📁 file/
│   │           │   ├── 📄 file_list_widget_test.dart
│   │           │   ├── 📄 file_item_widget_test.dart
│   │           │   └── 📄 file_preview_widget_test.dart
│   │           ├── 📁 network/
│   │           │   ├── 📄 device_list_widget_test.dart
│   │           │   ├── 📄 connection_widget_test.dart
│   │           │   └── 📄 transfer_widget_test.dart
│   │           └── 📁 ai/
│   │               ├── 📄 ai_analyzer_widget_test.dart
│   │               ├── 📄 ai_search_widget_test.dart
│   │               └── 📄 ai_recommendations_widget_test.dart
│   ├── 📁 widget/                     # Widget Tests
│   │   ├── 📄 screens/
│   │   │   ├── 📄 home_screen_widget_test.dart
│   │   │   ├── 📄 file_management_screen_widget_test.dart
│   │   │   ├── 📄 network_sharing_screen_widget_test.dart
│   │   │   └── 📄 ai_features_screen_widget_test.dart
│   │   └── 📁 widgets/
│   │       ├── 📄 common/
│   │       │   ├── 📄 app_scaffold_widget_test.dart
│   │       │   ├── 📄 app_bar_widget_test.dart
│   │       │   └── 📄 app_drawer_widget_test.dart
│   │       ├── 📄 file/
│   │       │   ├── 📄 file_list_widget_test.dart
│   │       │   ├── 📄 file_item_widget_test.dart
│   │       │   └── 📄 file_preview_widget_test.dart
│   │       ├── 📄 network/
│   │       │   ├── 📄 device_list_widget_test.dart
│   │       │   ├── 📄 connection_widget_test.dart
│   │       │   └── 📄 transfer_widget_test.dart
│   │       └── 📁 ai/
│   │           ├── 📄 ai_analyzer_widget_test.dart
│   │           ├── 📄 ai_search_widget_test.dart
│   │           └── 📄 ai_recommendations_widget_test.dart
│   └── 📁 integration/                # Integration Tests
│       ├── 📄 app_integration_test.dart
│       ├── 📄 ai_integration_test.dart
│       ├── 📄 network_integration_test.dart
│       ├── 📄 config_integration_test.dart
│       └── 📄 full_system_integration_test.dart
│
├── 📁 docs/                            # Documentation
│   ├── 📄 README.md                   # Main documentation
│   ├── 📄 API.md                     # API Documentation
│   ├── 📄 ARCHITECTURE.md             # Architecture Documentation
│   ├── 📄 PARAMETERIZATION_GUIDE.md  # Parameterization Guide
│   ├── 📄 PROJECT_ORGANIZATION.md   # Project Organization Guide
│   ├── 📄 ENHANCED_ORGANIZATION.md  # Enhanced Organization Guide
│   ├── 📄 NAMING_CONVENTIONS.md      # Naming Conventions Guide
│   ├── 📄 CODE_FORMATTING.md         # Code Formatting Guide
│   ├── 📄 TREE_HIERARCHY.md          # Tree Hierarchy Guide
│   ├── 📄 DEPLOYMENT.md              # Deployment Guide
│   ├── 📄 CONTRIBUTING.md             # Contributing Guidelines
│   ├── 📄 CHANGELOG.md                # Change Log
│   ├── 📄 features/                  # Feature Documentation
│   │   ├── 📄 AI_FEATURES.md
│   │   ├── 📄 NETWORK_FEATURES.md
│   │   ├── 📄 SECURITY_FEATURES.md
│   │   └── 📄 PERFORMANCE_FEATURES.md
│   └── 📄 guides/                    # User Guides
│       ├── 📄 USER_GUIDE.md
│       ├── 📄 DEVELOPER_GUIDE.md
│       ├── 📄 ADMINISTRATOR_GUIDE.md
│       └── 📄 TROUBLESHOOTING_GUIDE.md
│
├── 📁 assets/                          # Application Assets
│   ├── 📁 images/                    # Images
│   │   ├── 📁 logos/
│   │   │   ├── 📄 app_icon.png
│   │   │   ├── 📄 app_icon_512.png
│   │   │   └── 📄 splash_screen.png
│   │   ├── 📁 icons/
│   │   │   ├── 📄 file_icon.png
│   │   │   ├── 📄 folder_icon.png
│   │   │   ├── 📄 network_icon.png
│   │   │   ├── 📄 ai_icon.png
│   │   │   └── 📄 settings_icon.png
│   │   └── 📁 screenshots/
│   │       ├── 📄 home_screen.png
│   │       ├── 📄 file_management.png
│   │       ├── 📄 network_sharing.png
│   │       ├── 📄 ai_features.png
│   │       └── 📄 settings.png
│   ├── 📁 fonts/                     # Custom Fonts
│   │   ├── 📄 Roboto-Regular.ttf
│   │   ├── 📄 Roboto-Bold.ttf
│   │   ├── 📄 Roboto-Italic.ttf
│   │   └── 📄 RobotoMono-Regular.ttf
│   └── 📁 data/                      # Application Data
│       ├── 📄 sample_ai_data.json
│       ├── 📄 sample_network_data.json
│       └── 📄 sample_config_data.json
│
├── 📁 scripts/                         # Build and Utility Scripts
│   ├── 📄 build.sh                   # Build Script (Linux/Mac)
│   ├── 📄 build.bat                 # Build Script (Windows)
│   ├── 📄 test.sh                   # Test Script (Linux/Mac)
│   ├── 📄 test.bat                 # Test Script (Windows)
│   ├── 📄 deploy.sh                # Deployment Script (Linux/Mac)
│   ├── 📄 deploy.bat                # Deployment Script (Windows)
│   ├── 📄 setup.sh                 # Setup Script (Linux/Mac)
│   ├── 📄 setup.bat                 # Setup Script (Windows)
│   └── 📄 tools/                    # Utility Tools
│       ├── 📄 code_generator.sh      # Code generator tool
│       ├── 📄 config_validator.sh    # Configuration validator
│       └── 📄 health_checker.sh       # Health checker tool
│
├── 📁 web/                             # Web Build Output
│   ├── 📄 index.html                # Web App Entry
│   ├── 📄 main.dart.js              # Compiled Dart
│   ├── 📄 flutter.js                # Flutter Web Runtime
│   ├── 📄 assets/                   # Web Assets
│   │   ├── 📁 icons/
│   │   │   ├── 📄 Icon-192.png
│   │   │   ├── 📄 Icon-512.png
│   │   │   └── 📄 Icon-maskable-192.png
│   │   └── 📁 images/
│   │       └── 📄 app_logo.png
│   └── 📁 manifest.json             # Web App Manifest
│
├── 📁 android/                         # Android Build Output
│   ├── 📄 app/
│   │   ├── 📁 src/
│   │   │   ├── 📁 main/
│   │   │   │   ├── 📄 AndroidManifest.xml
│   │   │   │   ├── 📁 kotlin/
│   │   │   │   │   └── 📄 MainActivity.kt
│   │   │   │   └── 📁 res/
│   │   │   │       ├── 📁 values/
│   │   │   │       ├── 📄 styles.xml
│   │   │   │       ├── 📄 colors.xml
│   │   │   │       └── 📄 strings.xml
│   │   │   └── 📁 assets/
│   │   │           ├── 📁 ic_launcher/
│   │   │           └── 📁 mipmap/
│   │   ├── 📄 build.gradle.kts
│   │   └── 📄 proguard-rules.pro
│   ├── 📄 gradle/
│   │   └── 📄 wrapper/
│   ├── 📄 gradle.properties
│   ├── 📄 settings.gradle
│   └── 📄 build.gradle
│
├── 📁 ios/                             # iOS Build Output
│   ├── 📄 Runner/
│   │   ├── 📁 Assets.xcassets/
│   │   │   ├── 📁 AppIcon.appiconset/
│   │   │   ├── 📁 LaunchImage.launchimage/
│   │   │   └── 📁 Contents.json
│   │   ├── 📁 Base.lproj/
│   │   │   └── 📄 project.pbxproj
│   │   ├── 📄 Configs/
│   │   │   ├── 📄 Debug.xcconfig
│   │   │   ├── 📄 Profile.xcconfig
│   │   │   └── 📄 Release.xcconfig
│   │   ├── 📄 AppDelegate.swift
│   │   └── 📄 Info.plist
│   ├── 📄 Runner.xcworkspace/
│   │   ├── 📁 xcshareddata/
│   │   │   └── 📄 project.pbxproj
│   │   └── 📁 xcuserdata/
│   └── 📄 Flutter.podspec
│
├── 📁 windows/                         # Windows Build Output
│   ├── 📁 flutter/
│   │   ├── 📁 CMakeLists.txt
│   │   ├── 📄 generated_plugin_registrant.cc
│   │   ├── 📄 generated_plugin_registrant.h
│   │   └── 📄 runner_main.cpp
│   ├── 📁 runner/
│   │   ├── 📁 CMakeLists.txt
│   │   ├── 📄 flutter_window.cpp
│   │   ├── 📄 main.cpp
│   │   ├── 📄 resource.h
│   │   ├── 📄 Runner.rc
│   │   └── 📁 utils.cpp
│   ├── 📁 CMakeLists.txt
│   └── 📄 runner.exe
│
├── 📁 linux/                           # Linux Build Output
│   ├── 📁 flutter/
│   │   ├── 📄 CMakeLists.txt
│   │   ├── 📄 generated_plugin_registrant.cc
│   │   ├── 📄 generated_plugin_registrant.h
│   │   └── 📄 runner_main.cc
│   ├── 📁 runner/
│   │   ├── 📄 CMakeLists.txt
│   │   ├── 📄 main.cc
│   │   └── 📄 my_application.cc
│   ├── 📄 CMakeLists.txt
│   └── 📄 isuite
│
├── 📁 macos/                           # macOS Build Output
│   ├── 📁 Flutter/
│   │   ├── 📄 Flutter-Debug.xcconfig
│   │   ├── 📄 Flutter-Release.xcconfig
│   │   ├── 📄 GeneratedPluginRegistrant.swift
│   │   └── 📄 MainFlutterWindow.swift
│   ├── 📁 Runner/
│   │   ├── 📁 Assets.xcassets/
│   │   │   ├── 📁 AppIcon.appiconset/
│   │   │   └── 📄 Contents.json
│   │   ├── 📁 Base.lproj/
│   │   │   └── 📄 project.pbxproj
│   │   ├── 📁 Configs/
│   │   │   ├── 📄 DebugProfile.entitlements
│   │   │   ├── 📄 Debug.xcconfig
│   │   │   ├── 📄 Release.entitlements
│   │   │   └── 📄 Release.xcconfig
│   │   ├── 📄 AppDelegate.swift
│   │   ├── 📄 MainFlutterWindow.swift
│   │   └── 📄 Info.plist
│   ├── 📄 Runner.xcworkspace/
│   │   ├── 📁 xcshareddata/
│   │   │   └── 📄 project.pbxproj
│   │   └── 📁 xcuserdata/
│   └── 📄 Flutter.podspec
│
├── 📁 .github/                         # GitHub Configuration
│   ├── 📁 workflows/                  # GitHub Actions
│   │   ├── 📄 ci.yml                   # Continuous Integration
│   │   ├── 📄 cd.yml                   # Continuous Deployment
│   │   ├── 📄 test.yml                 # Testing Workflow
│   │   ├── 📄 security.yml             # Security Workflow
│   │   └── 📄 documentation.yml        # Documentation Workflow
│   ├── 📁 ISSUE_TEMPLATE/            # Issue Templates
│   │   ├── 📄 bug_report.md
│   │   ├── 📄 feature_request.md
│   │   └── 📄 question.md
│   ├── 📄 PULL_REQUEST_TEMPLATE.md   # Pull Request Template
│   ├── 📄 CONTRIBUTING.md             # Contributing Guidelines
│   └── 📄 CODE_OF_CONDUCT.md          # Code of Conduct
```

## 🌳 Layer Hierarchy

### 📋 **Layer 1: Application Layer**
```
lib/
├── main.dart                    # Application entry point
└── presentation/               # UI and presentation logic
    ├── enhanced_parameterized_app.dart
    ├── screens/                   # UI screens
    ├── widgets/                   # UI widgets
    ├── theme/                     # App theming
    └── providers/                 # State management
```

### 📋 **Layer 2: Domain Layer**
```
lib/domain/
├── index.dart                   # Domain exports
├── entities/                   # Domain entities
├── repositories/               # Repository interfaces
└── services/                   # Domain services
```

### 📋 **Layer 3: Data Layer**
```
lib/data/
├── index.dart                   # Data exports
├── models/                     # Data models
├── repositories/               # Repository implementations
└── datasources/               # Data sources
```

### 📋 **Layer 4: Core Layer**
```
lib/core/
├── orchestrator/               # 🆕 Application orchestration
├── registry/                   # 🆕 Service registry
├── config/                     # Configuration management
├── ai/                         # AI services
├── network/                    # Network services
├── backend/                    # Backend services
├── logging/                    # Logging system
├── performance/                # Performance optimization
├── security/                   # Security services
└── utils/                      # Utility functions
```

## 🔗 Component Hierarchy

### 📋 **Orchestration Hierarchy**
```
ApplicationOrchestrator
├── ServiceRegistry
│   ├── Infrastructure Services
│   ├── AI Services
│   ├── Network Services
│   └── Integration Services
├── Configuration Layer
├── Validation Suite
└── Event Coordination
```

### 📋 **Service Hierarchy**
```
ServiceRegistry
├── Infrastructure Layer
│   ├── Enhanced Logger
│   ├── Central Parameterized Config
│   ├── Component Relationship Manager
│   ├── Unified Service Orchestrator
│   ├── Enhanced Performance Manager
│   └── Enhanced Security Service
├── AI Services Layer
│   ├── AI File Organizer
│   ├── AI Advanced Search
│   ├── Smart File Categorizer
│   ├── AI Duplicate Detector
│   ├── AI File Recommendations
│   └── AI Services Integration
└── Network Services Layer
    ├── Network Discovery Service
    ├── Network Security Service
    ├── Enhanced Network File Sharing
    ├── Advanced FTP Client
    ├── WiFi Direct P2P Service
    ├── WebDAV Client
    └── Network File Sharing Integration
```

### 📋 **Configuration Hierarchy**
```
CentralParameterizedConfig
├── Application Configuration
├── AI Services Configuration
├── Network Services Configuration
├── Performance Configuration
├── Security Configuration
├── UI Configuration
└── Backend Configuration
```

## 📁 Configuration Hierarchy

### 📋 **Configuration Files**
```
config/
├── central_config.yaml         # Main configuration
├── environments/                 # Environment-specific
│   ├── development.yaml
│   ├── staging.yaml
│   └── production.yaml
├── ai/                         # AI services config
├── network/                    # Network services config
├── performance/                # Performance config
├── security/                    # Security config
├── ui/                         # UI config
├── backend/                    # Backend config
└── logging/                    # Logging config
```

### 📋 **Configuration Priority**
1. **Default Values**: Built-in defaults
2. **Environment Variables**: ISUITE_* environment variables
3. **Central Config**: central_config.yaml
4. **Environment Config**: development.yaml, staging.yaml, production.yaml
5. **Service Config**: ai_config.yaml, network_config.yaml, etc.
6. **Runtime Overrides**: Programmatic overrides

## 📱 Platform Hierarchy

### 📋 **Platform-Specific Build Outputs**
```
├── web/                         # Web platform
├── android/                     # Android platform
├── ios/                         # iOS platform
├── windows/                     # Windows platform
├── linux/                       # Linux platform
└── macos/                       # macOS platform
```

### 📋 **Platform-Specific Files**
```
web/
├── index.html                  # Web entry point
├── main.dart.js                # Compiled Dart
├── assets/                     # Web assets
└── manifest.json               # Web manifest

android/
├── app/                        # Android app
├── gradle/                     # Gradle build system
├── gradle.properties           # Gradle properties
└── build.gradle                # Build configuration

ios/
├── Runner/                     # iOS app
├── Runner.xcworkspace/          # Xcode workspace
└── Flutter.podspec              # Podspec file
```

## 🧪 Test Hierarchy

### 📋 **Test Organization**
```
test/
├── app_test.dart                # Main app test
├── unit/                       # Unit tests
│   ├── core/                     # Core layer tests
│   ├── data/                     # Data layer tests
│   ├── domain/                   # Domain layer tests
│   └── presentation/             # Presentation layer tests
├── widget/                     # Widget tests
│   ├── screens/                  # Screen widget tests
│   └── widgets/                  # Component widget tests
└── integration/                # Integration tests
    ├── app_integration_test.dart
    ├── ai_integration_test.dart
    └── network_integration_test.dart
```

### 📋 **Test Naming Convention**
```
[component]_test.dart           # Unit test
[component]_widget_test.dart      # Widget test
[component]_integration_test.dart # Integration test
```

## 📚 Documentation Hierarchy

### 📋 **Documentation Organization**
```
docs/
├── README.md                   # Main documentation
├── API.md                     # API documentation
├── ARCHITECTURE.md             # Architecture docs
├── guides/                    # User guides
├── features/                  # Feature documentation
└── CHANGELOG.md                # Change log
```

### 📋 **Documentation Categories**
```
├── User Guides                 # For end users
├── Developer Guides            # For developers
├── Administrator Guides         # For administrators
├── API Documentation           # For API users
├── Feature Documentation       # For feature understanding
└── Architecture Documentation   # For system understanding
```

## 🛠️ Scripts Hierarchy

### 📋 **Script Organization**
```
scripts/
├── build.sh                   # Build script (Linux/Mac)
├── build.bat                 # Build script (Windows)
├── test.sh                   # Test script (Linux/Mac)
├── test.bat                 # Test script (Windows)
├── deploy.sh                # Deployment script (Linux/Mac)
├── deploy.bat                # Deployment script (Windows)
├── setup.sh                 # Setup script (Linux/Mac)
├── setup.bat                 # Setup script (Windows)
└── tools/                    # Utility tools
    ├── code_generator.sh
    ├── config_validator.sh
    └── health_checker.sh
```

## 🎯 Hierarchy Benefits

### ✅ **Clear Organization**
- **Logical Grouping**: Related files grouped together
- **Layered Structure**: Clear separation of concerns
- **Consistent Naming**: Standardized naming conventions
- **Easy Navigation**: Intuitive directory structure

### ✅ **Maintainability**
- **Modular Design**: Components can be developed independently
- **Clear Dependencies**: Dependencies flow in one direction
- **Scalable Structure**: Easy to add new features
- **Testable Architecture**: Each layer can be tested independently

### ✅ **Developer Experience**
- **Easy File Location**: Intuitive file organization
- **Clear Import Paths**: Predictable import statements
- **Consistent Patterns**: Standardized patterns across files
- **Comprehensive Documentation**: Complete documentation coverage

## 🎯 Hierarchy Rules

### ✅ **Directory Structure Rules**
- Use `snake_case` for all directory names
- Group related functionality together
- Separate concerns into different layers
- Use descriptive names for directories
- Keep directory depth reasonable (max 4-5 levels)

### ✅ **File Organization Rules**
- Use `snake_case` for all file names
- Place files in appropriate directories
- Use descriptive file names
- Test files should be in corresponding test directories
- Use consistent naming patterns across similar files

### ✅ **Import Organization Rules**
- Group imports logically (dart, package, project)
- Use relative imports for internal files
- Use absolute imports for external packages
- Remove unused imports
- Sort imports alphabetically within groups

### ✅ **Documentation Organization Rules**
- Use descriptive names for documentation files
- Group related documentation together
- Use consistent naming for documentation
- Keep documentation up-to-date
- Use markdown format for documentation

This tree hierarchy ensures **proper organization, logical grouping, and clear relationships** between all components and files in the iSuite project! 🚀
