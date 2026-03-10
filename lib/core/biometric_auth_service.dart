import 'package:local_auth/local_auth.dart';
import 'logging_service.dart';

/// Biometric Authentication Service for enhanced security
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final LoggingService _logger = LoggingService();

  /// Authenticate user with biometrics
  Future<bool> authenticate() async {
    try {
      bool authenticated = false;
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        authenticated = await _auth.authenticate(
          localizedReason: 'Please authenticate to access iSuite',
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );
      }

      _logger.info('Biometric authentication result: $authenticated', 'BiometricAuthService');
      return authenticated;
    } catch (e) {
      _logger.error('Biometric authentication error: $e', 'BiometricAuthService');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      _logger.error('Error getting available biometrics: $e', 'BiometricAuthService');
      return [];
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      _logger.error('Error checking biometric availability: $e', 'BiometricAuthService');
      return false;
    }
  }
}
