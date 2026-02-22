# Project Organization Guide

## Overview

This document outlines the organizational structure and hierarchy of the iSuite project, ensuring logical connections and sensible arrangement of all components.

## 📁 Project Structure

```
iSuite/
├── 📄 README.md                    # Project overview and quick start
├── 📄 pubspec.yaml                # Dependencies and project configuration
├── 📄 analysis_options.yaml        # Code analysis and linting rules
├── 📁 lib/                       # Main source code directory
│   ├── 📄 main.dart               # Application entry point
│   ├── 📁 core/                  # Core utilities and shared services
│   ├── 📁 domain/                # Business logic and data models
│   ├── 📁 data/                  # Data access layer
│   └── 📁 presentation/          # User interface layer
├── 📁 assets/                    # Static resources (images, fonts, etc.)
├── 📁 docs/                     # Comprehensive documentation
├── 📁 test/                     # Test files and test utilities
├── 📁 backend/                   # Server-side code (if needed)
└── 📁 database/                  # Database schemas and migrations
```

## 🏗️ Architecture Hierarchy

### 1. Core Layer (Foundation)
**Purpose**: Shared utilities, constants, and services
**Connection**: Used by all other layers

```
core/
├── app_router.dart           # Navigation and routing
├── app_theme.dart           # Theme management
├── constants.dart           # App-wide constants
├── utils.dart              # Utility functions
├── extensions.dart          # Dart extensions
├── notification_service.dart # Local notifications
├── supabase_client.dart    # Cloud backend client
└── cloud_sync_service.dart # Data synchronization
```

### 2. Domain Layer (Business Logic)
**Purpose**: Business entities and rules
**Connection**: Defines data structure used by data and presentation layers

```
domain/
└── models/
    ├── task.dart              # Task entity
    ├── reminder.dart          # Reminder entity
    ├── note.dart             # Note entity
    ├── calendar_event.dart    # Calendar event entity
    ├── file.dart             # File entity
    ├── analytics.dart        # Analytics data
    ├── backup.dart           # Backup entity
    ├── search.dart           # Search entity
    ├── network_model.dart     # Network configuration
    ├── file_sharing_model.dart # File sharing configuration
    └── theme_model.dart     # Theme configuration
```

### 3. Data Layer (Data Access)
**Purpose**: Data persistence and retrieval
**Connection**: Implements repositories defined by domain models

```
data/
├── database_helper.dart      # SQLite database management
└── repositories/
    ├── task_repository.dart      # Task data operations
    ├── reminder_repository.dart  # Reminder data operations
    ├── note_repository.dart     # Note data operations
    ├── calendar_repository.dart # Calendar data operations
    ├── file_repository.dart     # File data operations
    ├── analytics_repository.dart # Analytics data operations
    ├── backup_repository.dart    # Backup data operations
    └── search_repository.dart   # Search data operations
```

### 4. Presentation Layer (User Interface)
**Purpose**: UI components and state management
**Connection**: Uses data layer repositories and domain models

```
presentation/
├── providers/               # State management
│   ├── theme_provider.dart      # Theme state
│   ├── user_provider.dart      # User state
│   ├── task_provider.dart      # Task state
│   ├── reminder_provider.dart  # Reminder state
│   ├── note_provider.dart     # Note state
│   ├── calendar_provider.dart  # Calendar state
│   ├── file_provider.dart     # File state
│   ├── analytics_provider.dart # Analytics state
│   ├── backup_provider.dart    # Backup state
│   ├── search_provider.dart   # Search state
│   ├── network_provider.dart   # Network state
│   └── file_sharing_provider.dart # File sharing state
├── screens/                 # UI screens
│   ├── splash_screen.dart       # App launch screen
│   ├── home_screen.dart       # Main dashboard
│   ├── tasks_screen.dart      # Task management
│   ├── reminders_screen.dart   # Reminder management
│   ├── notes_screen.dart      # Note management
│   ├── calendar_screen.dart    # Calendar view
│   ├── files_screen.dart      # File management
│   ├── analytics_screen.dart  # Analytics dashboard
│   ├── backup_screen.dart     # Backup/restore
│   ├── search_screen.dart     # Search functionality
│   ├── settings_screen.dart   # App settings
│   ├── profile_screen.dart    # User profile
│   ├── theme_customization_screen.dart # Theme customization
│   ├── network_screen.dart    # Network management
│   └── file_sharing_screen.dart # File sharing
└── widgets/                 # Reusable UI components
    ├── app_drawer.dart        # Navigation drawer
    ├── task_card.dart        # Task display card
    ├── note_card.dart       # Note display card
    ├── event_card.dart      # Calendar event card
    ├── file_card.dart       # File display card
    ├── add_task_dialog.dart  # Task creation dialog
    ├── note_editor.dart     # Rich text editor
    ├── calendar_view.dart    # Calendar widget
    ├── quick_actions.dart   # Quick action buttons
    └── [other widgets...]   # Additional UI components
```

## 🔗 Layer Connections

### Data Flow
1. **Presentation** → **Data**: UI components request data through providers
2. **Data** → **Domain**: Repositories use domain models for data operations
3. **Domain** → **Core**: Models use core utilities and constants
4. **Core** → **Presentation**: Core services provide notifications, themes, etc.

### Dependency Direction
```
Presentation Layer
       ↓
   Data Layer
       ↓
 Domain Layer
       ↓
   Core Layer
```

## 📋 Documentation Hierarchy

### User Documentation
- **USER_GUIDE.md**: Complete user manual
- **[FEATURE]_FEATURE.md**: Detailed feature documentation

### Developer Documentation
- **DEVELOPER.md**: Development setup and guidelines
- **ARCHITECTURE.md**: System architecture overview
- **API.md**: Complete API reference
- **DATABASE_SCHEMA.md**: Database structure

### Technical Documentation
- **README.md**: Project overview and quick start
- **PROJECT_ORGANIZATION.md**: This document

## 🎯 Organization Principles

### 1. Separation of Concerns
- Each layer has a single responsibility
- Clear boundaries between layers
- Minimal coupling between components

### 2. Logical Grouping
- Related files grouped together
- Consistent naming conventions
- Intuitive directory structure

### 3. Scalability
- Easy to add new features
- Modular component design
- Clear extension points

### 4. Maintainability
- Consistent code patterns
- Comprehensive documentation
- Clear dependency flow

## 🔄 File Naming Conventions

### Files
- **snake_case**: `task_provider.dart`, `user_profile.dart`
- **Descriptive names**: Clear purpose indication
- **Consistent patterns**: Similar files follow same naming

### Classes
- **PascalCase**: `TaskProvider`, `UserProfile`
- **Descriptive names**: Clear purpose indication
- **Singular nouns**: `Task` not `Tasks`

### Constants
- **UPPER_CASE**: `DEFAULT_PADDING`, `API_BASE_URL`
- **Descriptive names**: Clear purpose indication
- **Grouped logically**: Related constants together

## 📊 Component Relationships

### Provider-Model Relationships
- Each provider manages one domain model
- Providers handle state and business logic
- Models define data structure and validation

### Screen-Provider Relationships
- Each screen uses relevant providers
- Providers injected through dependency injection
- Screens react to provider state changes

### Repository-Model Relationships
- Each repository handles one model type
- Repositories implement CRUD operations
- Models define repository interface contracts

## 🚀 Benefits of This Organization

1. **Maintainability**: Easy to locate and modify code
2. **Scalability**: Simple to add new features
3. **Testability**: Clear separation for unit testing
4. **Collaboration**: Team members can work independently
5. **Code Quality**: Consistent patterns and structure
6. **Documentation**: Comprehensive and accessible

This organization ensures that iSuite remains maintainable, scalable, and easy to understand as the project grows.
