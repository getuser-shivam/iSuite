# iSuite Project Structure

This document outlines the organized directory structure of the iSuite Flutter project.

## Root Directory Structure

```
iSuite/
├── README.md                    # Main project documentation
├── pubspec.yaml               # Flutter project configuration
├── .gitignore                 # Git ignore rules
├── run_windows.bat            # Windows build entry point
│
├── lib/                       # Dart source code
│   ├── main.dart
│   ├── app.dart
│   ├── core/                  # Core functionality
│   ├── features/              # Feature modules
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Utility functions
│
├── assets/                    # Static assets
│   ├── images/
│   ├── fonts/
│   └── data/
│
├── test/                      # Test files
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── scripts/                   # Build and setup scripts
│   ├── setup_flutter.ps1      # Flutter installation script
│   ├── run_windows.ps1        # Windows build script
│   └── README.md              # Scripts documentation
│
├── tools/                     # Development tools
│   └── flutter/               # Flutter SDK (auto-installed)
│
├── config/                    # Configuration files
│   ├── analysis_options.yaml  # Dart analysis configuration
│   ├── .metadata             # Flutter metadata
│   └── isuite.iml            # IntelliJ module file
│
├── flutter/                   # Flutter-specific files
│   ├── .dart_tool/           # Dart build tools
│   ├── .flutter-plugins-dependencies
│   └── pubspec.lock          # Dependency lock file
│
├── database/                  # Database files
│   ├── migrations/
│   ├── seeds/
│   └── schemas/
│
├── docs/                      # Documentation
│   ├── api/
│   ├── architecture/
│   └── user_guide/
│
├── build/                     # Build outputs (generated)
│   ├── windows/
│   ├── android/
│   └── web/
│
├── android/                   # Android platform code
├── ios/                       # iOS platform code
├── windows/                   # Windows platform code
├── linux/                     # Linux platform code
├── macos/                     # macOS platform code
└── web/                       # Web platform code
│
├── .idea_backup/              # IntelliJ backup (gitignored)
├── .vscode_backup/            # VSCode backup (gitignored)
└── .git/                      # Git repository
```

## Directory Explanations

### `/lib/`
Contains all Dart source code for the application. Organized into:
- `core/`: Core business logic, models, and services
- `features/`: Feature-specific modules (e.g., auth, dashboard, tools)
- `widgets/`: Reusable UI components
- `utils/`: Helper functions and utilities

### `/scripts/`
PowerShell scripts for automating common development tasks:
- `setup_flutter.ps1`: Automatically installs Flutter SDK
- `run_windows.ps1`: Builds and runs the Windows application
- `README.md`: Detailed usage instructions

### `/tools/`
Contains development tools, primarily the Flutter SDK installation.

### `/config/`
Configuration files that control project behavior:
- `analysis_options.yaml`: Dart static analysis rules
- `.metadata`: Flutter project metadata
- `isuite.iml`: IntelliJ IDEA module configuration

### `/flutter/`
Flutter-specific files that are generated during development:
- `.dart_tool/`: Dart build artifacts
- `.flutter-plugins-dependencies`: Plugin dependency information
- `pubspec.lock`: Locked dependency versions

### `/database/`
Database-related files:
- `migrations/`: Database schema migrations
- `seeds/`: Initial data seeding scripts
- `schemas/`: Database schema definitions

### `/docs/`
Project documentation:
- `api/`: API documentation
- `architecture/`: System architecture documentation
- `user_guide/`: End-user documentation

## Platform-Specific Directories

Each platform directory contains the native code and configuration needed for that platform:

- `/android/`: Android app configuration and native code
- `/ios/`: iOS app configuration and native code
- `/windows/`: Windows app configuration and native code
- `/linux/`: Linux app configuration and native code
- `/macos/`: macOS app configuration and native code
- `/web/`: Web app configuration and assets

## Build and Development Workflow

1. **Initial Setup:**
   ```cmd
   run_windows.bat -Setup
   ```

2. **Development:**
   ```cmd
   run_windows.bat
   ```

3. **Clean Build:**
   ```cmd
   run_windows.bat -Clean
   ```

4. **Release Build:**
   ```cmd
   run_windows.bat -Release
   ```

## Git Organization

- **Tracked:** Source code, configuration, documentation, and platform files
- **Ignored:** Build artifacts, IDE files, tools, and generated files
- **Backup:** Original IDE configurations stored in `_backup` directories

## Notes

- The project follows Flutter best practices for directory organization
- All build artifacts are in `/build/` and excluded from version control
- Development tools are self-contained in `/tools/` for reproducible builds
- Configuration is centralized in `/config/` for easy management
