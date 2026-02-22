import 'package:flutter_test/flutter_test.dart';
import 'package:isuite/core/central_config.dart';

void main() {
  group('CentralConfig', () {
    test('should be a singleton', () {
      final config1 = CentralConfig.instance;
      final config2 = CentralConfig.instance;
      expect(config1, equals(config2));
    });

    test('should return correct app name', () {
      expect(CentralConfig.instance.appName, equals('iSuite'));
    });

    test('should return correct app version', () {
      expect(CentralConfig.instance.appVersion, equals('1.0.0'));
    });

    test('should return correct build number', () {
      expect(CentralConfig.instance.buildNumber, equals('1'));
    });

    test('should return correct primary framework', () {
      expect(CentralConfig.instance.primaryFramework, equals('Flutter'));
    });

    test('should return correct backend framework', () {
      expect(CentralConfig.instance.backendFramework, equals('Supabase'));
    });

    test('should return correct local database', () {
      expect(CentralConfig.instance.localDatabase, equals('SQLite'));
    });

    test('should return correct default port', () {
      expect(CentralConfig.instance.defaultPort, equals(8080));
    });

    test('should return correct default wifi SSID', () {
      expect(CentralConfig.instance.defaultWifiSSID, equals('iSuite_Share'));
    });

    test('should return correct default wifi password', () {
      expect(CentralConfig.instance.defaultWifiPassword, equals('isuite123'));
    });

    test('should return correct default timeout', () {
      expect(CentralConfig.instance.defaultTimeout, equals(const Duration(seconds: 30)));
    });

    test('should return correct supported platforms', () {
      final platforms = CentralConfig.instance.supportedPlatforms;
      expect(platforms, contains('android'));
      expect(platforms, contains('ios'));
      expect(platforms, contains('windows'));
      expect(platforms.length, equals(6));
    });

    test('should return correct UI parameters', () {
      expect(CentralConfig.instance.appTitle, equals('iSuite - Owlfiles File Manager'));
      expect(CentralConfig.instance.wifiScreenTitle, equals('Network Management'));
      expect(CentralConfig.instance.ftpScreenTitle, equals('FTP Client'));
      expect(CentralConfig.instance.filesTabTitle, equals('Files'));
      expect(CentralConfig.instance.networkTabTitle, equals('Network'));
      expect(CentralConfig.instance.ftpTabTitle, equals('FTP'));
    });

    test('should return correct UI dimensions', () {
      expect(CentralConfig.instance.defaultPadding, equals(16.0));
      expect(CentralConfig.instance.defaultMargin, equals(16.0));
      expect(CentralConfig.instance.cardElevation, equals(2.0));
      expect(CentralConfig.instance.borderRadius, equals(12.0));
      expect(CentralConfig.instance.wifiListHeight, equals(300.0));
      expect(CentralConfig.instance.animationIconSize, equals(48.0));
      expect(CentralConfig.instance.emptyStateIconSize, equals(64.0));
      expect(CentralConfig.instance.smallIconSize, equals(18.0));
      expect(CentralConfig.instance.subtitleFontSize, equals(12.0));
    });

    test('should return correct animation parameters', () {
      expect(CentralConfig.instance.scanAnimationDuration, equals(const Duration(seconds: 2)));
      expect(CentralConfig.instance.scanAnimationMinScale, equals(0.8));
      expect(CentralConfig.instance.scanAnimationMaxScale, equals(1.2));
    });

    test('should return correct network tool parameters', () {
      expect(CentralConfig.instance.wifiScanDelay, equals(const Duration(seconds: 2)));
      expect(CentralConfig.instance.portScanTimeout, equals(const Duration(milliseconds: 500)));
      expect(CentralConfig.instance.portScanBatchSize, equals(10));
      expect(CentralConfig.instance.portScanBatchDelayMs, equals(0));
      expect(CentralConfig.instance.ftpTimeout, equals(const Duration(seconds: 30)));
    });

    test('should return correct signal strength thresholds', () {
      expect(CentralConfig.instance.excellentSignalThreshold, equals(-50));
      expect(CentralConfig.instance.goodSignalThreshold, equals(-60));
      expect(CentralConfig.instance.fairSignalThreshold, equals(-70));
    });

    test('should return correct colors', () {
      // Test that colors are not null (actual color values tested in integration)
      expect(CentralConfig.instance.primaryColor, isNotNull);
      expect(CentralConfig.instance.secondaryColor, isNotNull);
      expect(CentralConfig.instance.accentColor, isNotNull);
      expect(CentralConfig.instance.backgroundColor, isNotNull);
      expect(CentralConfig.instance.surfaceColor, isNotNull);
      expect(CentralConfig.instance.errorColor, isNotNull);
      expect(CentralConfig.instance.successColor, isNotNull);
      expect(CentralConfig.instance.wifiSignalExcellent, isNotNull);
      expect(CentralConfig.instance.wifiSignalGood, isNotNull);
      expect(CentralConfig.instance.wifiSignalFair, isNotNull);
      expect(CentralConfig.instance.wifiSignalWeak, isNotNull);
    });
  });
}
