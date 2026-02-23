# iSuite Naming Conventions and Project Structure

## 📋 **Official Naming Conventions**

### **File Naming**
- **Classes**: `PascalCase.dart` (e.g., `UserService.dart`)
- **Libraries/Directories**: `snake_case` (e.g., `user_service.dart`, `file_management/`)
- **Test Files**: `*_test.dart` (e.g., `user_service_test.dart`)
- **Constants**: `constants.dart`
- **Models**: `*_model.dart` or `*_entity.dart`

### **Class Naming**
- **Services**: `ServiceNameService` (e.g., `UserService`, `FileManagerService`)
- **Models**: `ModelName` (e.g., `User`, `FileInfo`)
- **Enums**: `EnumName` (e.g., `FileType`, `ConnectionStatus`)
- **Interfaces**: `InterfaceName` (abstract classes without `_`)
- **Private Classes**: `_PrivateClassName`

### **Variable Naming**
- **Public**: `camelCase` (e.g., `userName`, `fileList`)
- **Private**: `_camelCase` (e.g., `_userName`, `_fileList`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `MAX_FILE_SIZE`)
- **Static Constants**: `UPPER_SNAKE_CASE`

### **Method Naming**
- **Public**: `camelCase` (e.g., `getUser()`, `saveFile()`)
- **Private**: `_camelCase` (e.g., `_getUser()`, `_saveFile()`)
- **Getters**: `propertyName` (no get prefix)
- **Setters**: `propertyName` (no set prefix)
- **Factory**: `factoryMethodName`

### **Directory Structure**
```
lib/
├── core/                          # Core infrastructure
│   ├── config/                    # Configuration services
│   ├── logging/                   # Logging infrastructure
│   ├── security/                  # Security services
│   ├── error_handling/           # Error handling
│   └── ui/                        # UI utilities
├── domain/                        # Business logic
│   ├── entities/                  # Domain entities
│   ├── services/                  # Domain services
│   │   ├── file_management/       # File management domain
│   │   ├── network/               # Network domain
│   │   ├── database/              # Database domain
│   │   └── caching/               # Caching domain
│   └── repositories/              # Data access
├── application/                   # Application layer
│   ├── services/                  # Application services
│   │   ├── testing/               # Testing services
│   │   ├── analytics/             # Analytics services
│   │   └── performance/           # Performance services
│   ├── use_cases/                 # Use cases
│   └── dtos/                      # Data transfer objects
├── infrastructure/                # External concerns
│   ├── core/                      # Infrastructure core
│   │   ├── config/               # Config infrastructure
│   │   ├── logging/              # Logging infrastructure
│   │   ├── security/             # Security infrastructure
│   │   └── error_handling/       # Error handling infrastructure
│   └── services/                 # External services
│       ├── cloud/                # Cloud services
│       └── notifications/        # Notification services
├── presentation/                  # UI/Presentation layer
│   ├── app.dart                   # Main app
│   ├── providers/                # State management providers
│   ├── screens/                   # Screen widgets
│   ├── widgets/                   # Reusable widgets
│   └── themes/                    # Theme definitions
├── data/                          # Data layer (legacy)
├── features/                      # Feature modules (legacy)
└── services/                      # Services (legacy)
```

### **Package Naming**
- **Internal Packages**: `snake_case` (e.g., `file_management`, `network_services`)
- **External Packages**: Follow pub.dev conventions

### **Import Organization**
```dart
// 1. Dart SDK imports (alphabetical)
import 'dart:async';
import 'dart:convert';

// 2. Flutter SDK imports (alphabetical)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Third-party packages (alphabetical)
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 4. Project imports (relative, grouped by layer)
import '../domain/entities/user.dart';
import '../domain/services/user_service.dart';
import '../infrastructure/services/api_client.dart';
import '../presentation/widgets/user_card.dart';

// 5. Export statements (if any)
export 'user_service.dart';
```

### **Documentation**
- **Classes**: Document with `///` describing purpose and usage
- **Methods**: Document with `///` for public APIs
- **Parameters**: Use `@param` for complex parameters
- **Returns**: Use `@return` for non-obvious return types

### **Code Formatting**
- **Line Length**: 120 characters maximum
- **Indentation**: 2 spaces (Flutter standard)
- **Braces**: Same line for functions/classes, new line for control structures
- **Spaces**: Around operators, after commas, before colons in maps
- **Empty Lines**: Between logical blocks, before/after class members

### **Example Code Structure**
```dart
/// User service for managing user operations
/// Provides authentication, profile management, and user data operations
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final UserRepository _repository;
  final LoggerService _logger;

  /// Authenticate user with email and password
  /// @param email User email address
  /// @param password User password
  /// @return Future<User> authenticated user
  Future<User> authenticate({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Authenticating user: $email');

      final user = await _repository.authenticate(
        email: email,
        password: password,
      );

      _logger.info('User authenticated successfully: ${user.id}');
      return user;

    } catch (e) {
      _logger.error('Authentication failed for: $email', error: e);
      rethrow;
    }
  }
}
```

### **File Headers**
```dart
/// File: lib/domain/services/user_service.dart
/// Description: User service implementation
/// Author: iSuite Team
/// Date: 2024-01-15
/// Version: 1.0.0
```

### **Configuration Keys**
- **Service Settings**: `serviceName.settingName`
- **Feature Flags**: `feature.featureName.enabled`
- **UI Settings**: `ui.componentName.propertyName`
- **Security**: `security.componentName.settingName`
- **Performance**: `performance.componentName.settingName`

### **Test File Structure**
```
test/
├── unit/
│   ├── domain/
│   │   └── services/
│   └── infrastructure/
├── integration/
└── widget/
```

### **Asset Organization**
```
assets/
├── images/
├── icons/
├── fonts/
└── animations/
```

This naming convention document should be followed throughout the iSuite project to maintain consistency and readability.
