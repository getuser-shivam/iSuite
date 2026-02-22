import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance =>
      _instance ??= PerformanceMonitor._internal();
  PerformanceMonitor._internal();

  // Monitoring State
  bool _isInitialized = false;
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  Duration _monitoringInterval = Duration(seconds: 5);

  // Performance Metrics
  final Map<String, PerformanceMetric> _metrics = {};
  final List<PerformanceSnapshot> _snapshots = [];
  final Map<String, List<PerformanceDataPoint>> _dataHistory = {};

  // System Information
  DeviceInfoPlugin? _deviceInfo;
  PackageInfo? _packageInfo;
  Map<String, dynamic> _systemInfo = {};

  // Performance Thresholds
  final Map<String, PerformanceThreshold> _thresholds = {};
  final List<PerformanceAlert> _alerts = [];

  // Profiling
  final Map<String, ProfileSession> _profileSessions = {};
  final Map<String, List<ProfileData>> _profileData = {};

  // Memory Monitoring
  MemoryInfo _currentMemoryInfo = MemoryInfo();
  List<MemorySnapshot> _memoryHistory = [];

  // CPU Monitoring
  CPUInfo _currentCPUInfo = CPUInfo();
  List<CPUSnapshot> _cpuHistory = [];

  // Network Monitoring
  NetworkInfo _currentNetworkInfo = NetworkInfo();
  List<NetworkSnapshot> _networkHistory = [];

  // Render Performance
  RenderInfo _currentRenderInfo = RenderInfo();
  List<RenderSnapshot> _renderHistory = [];

  // Configuration
  bool _enableMemoryMonitoring = true;
  bool _enableCPUMonitoring = true;
  bool _enableNetworkMonitoring = true;
  bool _enableRenderMonitoring = true;
  bool _enableProfiling = false;
  int _maxSnapshots = 1000;
  int _maxDataPoints = 10000;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  Map<String, PerformanceMetric> get metrics => Map.from(_metrics);
  List<PerformanceSnapshot> get snapshots => List.from(_snapshots);
  List<PerformanceAlert> get alerts => List.from(_alerts);
  MemoryInfo get currentMemoryInfo => _currentMemoryInfo;
  CPUInfo get currentCPUInfo => _currentCPUInfo;
  NetworkInfo get currentNetworkInfo => _currentNetworkInfo;
  RenderInfo get currentRenderInfo => _currentRenderInfo;

  /// Initialize Performance Monitor
  Future<bool> initialize({
    Duration? monitoringInterval,
    bool enableMemoryMonitoring = true,
    bool enableCPUMonitoring = true,
    bool enableNetworkMonitoring = true,
    bool enableRenderMonitoring = true,
    bool enableProfiling = false,
    int? maxSnapshots,
    int? maxDataPoints,
  }) async {
    if (_isInitialized) return true;

    try {
      _monitoringInterval = monitoringInterval ?? _monitoringInterval;
      _enableMemoryMonitoring = enableMemoryMonitoring;
      _enableCPUMonitoring = enableCPUMonitoring;
      _enableNetworkMonitoring = enableNetworkMonitoring;
      _enableRenderMonitoring = enableRenderMonitoring;
      _enableProfiling = enableProfiling;
      _maxSnapshots = maxSnapshots ?? _maxSnapshots;
      _maxDataPoints = maxDataPoints ?? _maxDataPoints;

      // Initialize device info
      _deviceInfo = DeviceInfoPlugin();
      await _initializeSystemInfo();

      // Initialize package info
      _packageInfo = await PackageInfo.fromPlatform();

      // Initialize thresholds
      await _initializeThresholds();

      // Initialize metrics
      await _initializeMetrics();

      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeSystemInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo!.androidInfo;
        _systemInfo = {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'hardware': androidInfo.hardware,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo!.iosInfo;
        _systemInfo = {
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'localizedModel': iosInfo.localizedModel,
          'systemName': iosInfo.systemName,
          'utsname': {
            'machine': iosInfo.utsname.machine,
            'nodename': iosInfo.utsname.nodename,
            'release': iosInfo.utsname.release,
            'sysname': iosInfo.utsname.sysname,
            'version': iosInfo.utsname.version,
          },
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo!.windowsInfo;
        _systemInfo = {
          'platform': 'Windows',
          'version': windowsInfo.version,
          'edition': windowsInfo.edition,
          'buildNumber': windowsInfo.buildNumber,
          'productName': windowsInfo.productName,
          'registeredOwner': windowsInfo.registeredOwner,
        };
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo!.macOsInfo;
        _systemInfo = {
          'platform': 'macOS',
          'version': macOsInfo.majorVersion,
          'minorVersion': macOsInfo.minorVersion,
          'patchVersion': macOsInfo.patchVersion,
          'model': macOsInfo.model,
          'computerName': macOsInfo.computerName,
          'hostName': macOsInfo.hostName,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo!.linuxInfo;
        _systemInfo = {
          'platform': 'Linux',
          'version': linuxInfo.version,
          'id': linuxInfo.id,
          'idLike': linuxInfo.idLike,
          'name': linuxInfo.name,
          'versionCodename': linuxInfo.versionCodename,
          'versionId': linuxInfo.versionId,
        };
      }
    } catch (e) {
      _systemInfo = {
        'platform': Platform.operatingSystem,
        'error': e.toString()
      };
    }
  }

  Future<void> _initializeThresholds() async {
    _thresholds['memory_usage'] = PerformanceThreshold(
      name: 'Memory Usage',
      warningThreshold: 80.0,
      criticalThreshold: 90.0,
      unit: '%',
      description: 'Memory usage percentage',
    );

    _thresholds['cpu_usage'] = PerformanceThreshold(
      name: 'CPU Usage',
      warningThreshold: 70.0,
      criticalThreshold: 85.0,
      unit: '%',
      description: 'CPU usage percentage',
    );

    _thresholds['frame_rate'] = PerformanceThreshold(
      name: 'Frame Rate',
      warningThreshold: 45.0,
      criticalThreshold: 30.0,
      unit: 'fps',
      description: 'Rendering frame rate',
    );

    _thresholds['network_latency'] = PerformanceThreshold(
      name: 'Network Latency',
      warningThreshold: 500.0,
      criticalThreshold: 1000.0,
      unit: 'ms',
      description: 'Network response time',
    );

    _thresholds['app_startup_time'] = PerformanceThreshold(
      name: 'App Startup Time',
      warningThreshold: 3.0,
      criticalThreshold: 5.0,
      unit: 's',
      description: 'Application startup time',
    );
  }

  Future<void> _initializeMetrics() async {
    _metrics['memory'] = PerformanceMetric(
      name: 'Memory',
      type: MetricType.memory,
      unit: 'MB',
      currentValue: 0.0,
      averageValue: 0.0,
      minValue: 0.0,
      maxValue: 0.0,
      dataPoints: [],
    );

    _metrics['cpu'] = PerformanceMetric(
      name: 'CPU',
      type: MetricType.cpu,
      unit: '%',
      currentValue: 0.0,
      averageValue: 0.0,
      minValue: 0.0,
      maxValue: 0.0,
      dataPoints: [],
    );

    _metrics['network'] = PerformanceMetric(
      name: 'Network',
      type: MetricType.network,
      unit: 'ms',
      currentValue: 0.0,
      averageValue: 0.0,
      minValue: 0.0,
      maxValue: 0.0,
      dataPoints: [],
    );

    _metrics['render'] = PerformanceMetric(
      name: 'Render',
      type: MetricType.render,
      unit: 'fps',
      currentValue: 0.0,
      averageValue: 0.0,
      minValue: 0.0,
      maxValue: 0.0,
      dataPoints: [],
    );

    _metrics['storage'] = PerformanceMetric(
      name: 'Storage',
      type: MetricType.storage,
      unit: 'MB',
      currentValue: 0.0,
      averageValue: 0.0,
      minValue: 0.0,
      maxValue: 0.0,
      dataPoints: [],
    );
  }

  /// Start monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectMetrics();
    });

    // Initial collection
    _collectMetrics();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Collect performance metrics
  Future<void> _collectMetrics() async {
    final timestamp = DateTime.now();

    // Collect memory info
    if (_enableMemoryMonitoring) {
      await _collectMemoryInfo(timestamp);
    }

    // Collect CPU info
    if (_enableCPUMonitoring) {
      await _collectCPUInfo(timestamp);
    }

    // Collect network info
    if (_enableNetworkMonitoring) {
      await _collectNetworkInfo(timestamp);
    }

    // Collect render info
    if (_enableRenderMonitoring) {
      await _collectRenderInfo(timestamp);
    }

    // Create snapshot
    final snapshot = PerformanceSnapshot(
      timestamp: timestamp,
      memoryInfo: _currentMemoryInfo,
      cpuInfo: _currentCPUInfo,
      networkInfo: _currentNetworkInfo,
      renderInfo: _currentRenderInfo,
    );

    _snapshots.add(snapshot);

    // Limit snapshots
    if (_snapshots.length > _maxSnapshots) {
      _snapshots.removeRange(0, _snapshots.length - _maxSnapshots);
    }

    // Check thresholds
    _checkThresholds(snapshot);
  }

  Future<void> _collectMemoryInfo(DateTime timestamp) async {
    try {
      // In a real implementation, this would use platform-specific APIs
      // For now, we'll simulate memory info
      final totalMemory = 4096.0; // MB
      final usedMemory = Random().nextDouble() * totalMemory * 0.8;
      final freeMemory = totalMemory - usedMemory;

      _currentMemoryInfo = MemoryInfo(
        totalMemory: totalMemory,
        usedMemory: usedMemory,
        freeMemory: freeMemory,
        usagePercentage: (usedMemory / totalMemory) * 100,
        timestamp: timestamp,
      );

      // Update metric
      final metric = _metrics['memory']!;
      metric.currentValue = usedMemory;
      metric.dataPoints.add(PerformanceDataPoint(
        timestamp: timestamp,
        value: usedMemory,
      ));

      // Limit data points
      if (metric.dataPoints.length > _maxDataPoints) {
        metric.dataPoints
            .removeRange(0, metric.dataPoints.length - _maxDataPoints);
      }

      // Update statistics
      _updateMetricStatistics(metric);

      // Add to history
      _memoryHistory.add(MemorySnapshot(
        timestamp: timestamp,
        totalMemory: totalMemory,
        usedMemory: usedMemory,
        freeMemory: freeMemory,
        usagePercentage: (usedMemory / totalMemory) * 100,
      ));

      // Limit history
      if (_memoryHistory.length > 100) {
        _memoryHistory.removeRange(0, _memoryHistory.length - 100);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _collectCPUInfo(DateTime timestamp) async {
    try {
      // In a real implementation, this would use platform-specific APIs
      // For now, we'll simulate CPU info
      final usage = Random().nextDouble() * 100;

      _currentCPUInfo = CPUInfo(
        usage: usage,
        cores: Platform.numberOfProcessors,
        frequency: 2.4, // GHz
        temperature: 45.0 + Random().nextDouble() * 20, // Celsius
        timestamp: timestamp,
      );

      // Update metric
      final metric = _metrics['cpu']!;
      metric.currentValue = usage;
      metric.dataPoints.add(PerformanceDataPoint(
        timestamp: timestamp,
        value: usage,
      ));

      // Limit data points
      if (metric.dataPoints.length > _maxDataPoints) {
        metric.dataPoints
            .removeRange(0, metric.dataPoints.length - _maxDataPoints);
      }

      // Update statistics
      _updateMetricStatistics(metric);

      // Add to history
      _cpuHistory.add(CPUSnapshot(
        timestamp: timestamp,
        usage: usage,
        cores: Platform.numberOfProcessors,
        frequency: 2.4,
        temperature: 45.0 + Random().nextDouble() * 20,
      ));

      // Limit history
      if (_cpuHistory.length > 100) {
        _cpuHistory.removeRange(0, _cpuHistory.length - 100);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _collectNetworkInfo(DateTime timestamp) async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isConnected = connectivity != ConnectivityResult.none;

      // Simulate network metrics
      final latency = isConnected ? 50.0 + Random().nextDouble() * 100 : 0.0;
      final bandwidth =
          isConnected ? 1000.0 + Random().nextDouble() * 9000 : 0.0;

      _currentNetworkInfo = NetworkInfo(
        isConnected: isConnected,
        latency: latency,
        bandwidth: bandwidth,
        connectionType: connectivity.toString(),
        timestamp: timestamp,
      );

      // Update metric
      final metric = _metrics['network']!;
      metric.currentValue = latency;
      metric.dataPoints.add(PerformanceDataPoint(
        timestamp: timestamp,
        value: latency,
      ));

      // Limit data points
      if (metric.dataPoints.length > _maxDataPoints) {
        metric.dataPoints
            .removeRange(0, metric.dataPoints.length - _maxDataPoints);
      }

      // Update statistics
      _updateMetricStatistics(metric);

      // Add to history
      _networkHistory.add(NetworkSnapshot(
        timestamp: timestamp,
        isConnected: isConnected,
        latency: latency,
        bandwidth: bandwidth,
        connectionType: connectivity.toString(),
      ));

      // Limit history
      if (_networkHistory.length > 100) {
        _networkHistory.removeRange(0, _networkHistory.length - 100);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _collectRenderInfo(DateTime timestamp) async {
    try {
      // In a real implementation, this would use Flutter's performance overlay
      // For now, we'll simulate render info
      final frameRate = 55.0 + Random().nextDouble() * 5;
      final frameTime = 1000.0 / frameRate;
      final droppedFrames = Random().nextInt(5);

      _currentRenderInfo = RenderInfo(
        frameRate: frameRate,
        frameTime: frameTime,
        droppedFrames: droppedFrames,
        rasterTime: frameTime * 0.7,
        uiTime: frameTime * 0.3,
        timestamp: timestamp,
      );

      // Update metric
      final metric = _metrics['render']!;
      metric.currentValue = frameRate;
      metric.dataPoints.add(PerformanceDataPoint(
        timestamp: timestamp,
        value: frameRate,
      ));

      // Limit data points
      if (metric.dataPoints.length > _maxDataPoints) {
        metric.dataPoints
            .removeRange(0, metric.dataPoints.length - _maxDataPoints);
      }

      // Update statistics
      _updateMetricStatistics(metric);

      // Add to history
      _renderHistory.add(RenderSnapshot(
        timestamp: timestamp,
        frameRate: frameRate,
        frameTime: frameTime,
        droppedFrames: droppedFrames,
        rasterTime: frameTime * 0.7,
        uiTime: frameTime * 0.3,
      ));

      // Limit history
      if (_renderHistory.length > 100) {
        _renderHistory.removeRange(0, _renderHistory.length - 100);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _updateMetricStatistics(PerformanceMetric metric) {
    if (metric.dataPoints.isEmpty) return;

    final values = metric.dataPoints.map((dp) => dp.value).toList();
    metric.averageValue = values.reduce((a, b) => a + b) / values.length;
    metric.minValue = values.reduce(min);
    metric.maxValue = values.reduce(max);
  }

  void _checkThresholds(PerformanceSnapshot snapshot) {
    // Check memory threshold
    final memoryThreshold = _thresholds['memory_usage'];
    if (memoryThreshold != null) {
      if (snapshot.memoryInfo.usagePercentage >=
          memoryThreshold.criticalThreshold) {
        _createAlert(
          type: AlertType.critical,
          metric: 'memory',
          message:
              'Memory usage is critically high: ${snapshot.memoryInfo.usagePercentage.toStringAsFixed(1)}%',
          value: snapshot.memoryInfo.usagePercentage,
          threshold: memoryThreshold.criticalThreshold,
        );
      } else if (snapshot.memoryInfo.usagePercentage >=
          memoryThreshold.warningThreshold) {
        _createAlert(
          type: AlertType.warning,
          metric: 'memory',
          message:
              'Memory usage is high: ${snapshot.memoryInfo.usagePercentage.toStringAsFixed(1)}%',
          value: snapshot.memoryInfo.usagePercentage,
          threshold: memoryThreshold.warningThreshold,
        );
      }
    }

    // Check CPU threshold
    final cpuThreshold = _thresholds['cpu_usage'];
    if (cpuThreshold != null) {
      if (snapshot.cpuInfo.usage >= cpuThreshold.criticalThreshold) {
        _createAlert(
          type: AlertType.critical,
          metric: 'cpu',
          message:
              'CPU usage is critically high: ${snapshot.cpuInfo.usage.toStringAsFixed(1)}%',
          value: snapshot.cpuInfo.usage,
          threshold: cpuThreshold.criticalThreshold,
        );
      } else if (snapshot.cpuInfo.usage >= cpuThreshold.warningThreshold) {
        _createAlert(
          type: AlertType.warning,
          metric: 'cpu',
          message:
              'CPU usage is high: ${snapshot.cpuInfo.usage.toStringAsFixed(1)}%',
          value: snapshot.cpuInfo.usage,
          threshold: cpuThreshold.warningThreshold,
        );
      }
    }

    // Check frame rate threshold
    final frameRateThreshold = _thresholds['frame_rate'];
    if (frameRateThreshold != null) {
      if (snapshot.renderInfo.frameRate <=
          frameRateThreshold.criticalThreshold) {
        _createAlert(
          type: AlertType.critical,
          metric: 'render',
          message:
              'Frame rate is critically low: ${snapshot.renderInfo.frameRate.toStringAsFixed(1)} fps',
          value: snapshot.renderInfo.frameRate,
          threshold: frameRateThreshold.criticalThreshold,
        );
      } else if (snapshot.renderInfo.frameRate <=
          frameRateThreshold.warningThreshold) {
        _createAlert(
          type: AlertType.warning,
          metric: 'render',
          message:
              'Frame rate is low: ${snapshot.renderInfo.frameRate.toStringAsFixed(1)} fps',
          value: snapshot.renderInfo.frameRate,
          threshold: frameRateThreshold.warningThreshold,
        );
      }
    }

    // Check network latency threshold
    final networkThreshold = _thresholds['network_latency'];
    if (networkThreshold != null && snapshot.networkInfo.isConnected) {
      if (snapshot.networkInfo.latency >= networkThreshold.criticalThreshold) {
        _createAlert(
          type: AlertType.critical,
          metric: 'network',
          message:
              'Network latency is critically high: ${snapshot.networkInfo.latency.toStringAsFixed(1)} ms',
          value: snapshot.networkInfo.latency,
          threshold: networkThreshold.criticalThreshold,
        );
      } else if (snapshot.networkInfo.latency >=
          networkThreshold.warningThreshold) {
        _createAlert(
          type: AlertType.warning,
          metric: 'network',
          message:
              'Network latency is high: ${snapshot.networkInfo.latency.toStringAsFixed(1)} ms',
          value: snapshot.networkInfo.latency,
          threshold: networkThreshold.warningThreshold,
        );
      }
    }
  }

  void _createAlert({
    required AlertType type,
    required String metric,
    required String message,
    required double value,
    required double threshold,
  }) {
    final alert = PerformanceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      metric: metric,
      message: message,
      value: value,
      threshold: threshold,
      timestamp: DateTime.now(),
    );

    _alerts.add(alert);

    // Limit alerts
    if (_alerts.length > 100) {
      _alerts.removeRange(0, _alerts.length - 100);
    }
  }

  /// Start profiling
  String startProfiling(String name) {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    _profileSessions[sessionId] = ProfileSession(
      id: sessionId,
      name: name,
      startTime: DateTime.now(),
      endTime: null,
      duration: null,
    );

    _profileData[sessionId] = [];

    return sessionId;
  }

  /// Stop profiling
  void stopProfiling(String sessionId) {
    final session = _profileSessions[sessionId];
    if (session == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(session.startTime);

    _profileSessions[sessionId] = session.copyWith(
      endTime: endTime,
      duration: duration,
    );
  }

  /// Add profile data point
  void addProfileData(String sessionId, String operation, Duration duration) {
    final data = _profileData[sessionId];
    if (data == null) return;

    data.add(ProfileData(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
    ));
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'systemInfo': _systemInfo,
      'packageInfo': _packageInfo?.toMap(),
      'isMonitoring': _isMonitoring,
      'monitoringInterval': _monitoringInterval.inSeconds,
      'currentMetrics': {
        'memory': _currentMemoryInfo.toMap(),
        'cpu': _currentCPUInfo.toMap(),
        'network': _currentNetworkInfo.toMap(),
        'render': _currentRenderInfo.toMap(),
      },
      'metrics': _metrics.map((k, v) => MapEntry(k, v.toMap())),
      'thresholds': _thresholds.map((k, v) => MapEntry(k, v.toMap())),
      'alerts': _alerts.map((a) => a.toMap()).toList(),
      'snapshotsCount': _snapshots.length,
      'profileSessions': _profileSessions.map((k, v) => MapEntry(k, v.toMap())),
      'configuration': {
        'enableMemoryMonitoring': _enableMemoryMonitoring,
        'enableCPUMonitoring': _enableCPUMonitoring,
        'enableNetworkMonitoring': _enableNetworkMonitoring,
        'enableRenderMonitoring': _enableRenderMonitoring,
        'enableProfiling': _enableProfiling,
        'maxSnapshots': _maxSnapshots,
        'maxDataPoints': _maxDataPoints,
      },
    };
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    if (_snapshots.isEmpty) {
      return {
        'status': 'no_data',
        'message': 'No performance data available',
      };
    }

    final latest = _snapshots.last;
    final hourAgo = DateTime.now().subtract(Duration(hours: 1));
    final recentSnapshots =
        _snapshots.where((s) => s.timestamp.isAfter(hourAgo)).toList();

    return {
      'status': 'healthy',
      'lastUpdated': latest.timestamp.toIso8601String(),
      'current': {
        'memoryUsage': latest.memoryInfo.usagePercentage,
        'cpuUsage': latest.cpuInfo.usage,
        'frameRate': latest.renderInfo.frameRate,
        'networkLatency': latest.networkInfo.latency,
        'networkConnected': latest.networkInfo.isConnected,
      },
      'averages': {
        'memoryUsage': recentSnapshots
                .map((s) => s.memoryInfo.usagePercentage)
                .reduce((a, b) => a + b) /
            recentSnapshots.length,
        'cpuUsage': recentSnapshots
                .map((s) => s.cpuInfo.usage)
                .reduce((a, b) => a + b) /
            recentSnapshots.length,
        'frameRate': recentSnapshots
                .map((s) => s.renderInfo.frameRate)
                .reduce((a, b) => a + b) /
            recentSnapshots.length,
        'networkLatency': recentSnapshots
                .map((s) => s.networkInfo.latency)
                .reduce((a, b) => a + b) /
            recentSnapshots.length,
      },
      'alerts': {
        'total': _alerts.length,
        'critical': _alerts.where((a) => a.type == AlertType.critical).length,
        'warning': _alerts.where((a) => a.type == AlertType.warning).length,
        'info': _alerts.where((a) => a.type == AlertType.info).length,
      },
      'trends': _calculateTrends(),
    };
  }

  Map<String, dynamic> _calculateTrends() {
    if (_snapshots.length < 2) {
      return {
        'memory': 'stable',
        'cpu': 'stable',
        'render': 'stable',
        'network': 'stable'
      };
    }

    final recent = _snapshots.takeLast(10).toList();
    final older = _snapshots.skip(_snapshots.length - 20).take(10).toList();

    if (older.isEmpty) {
      return {
        'memory': 'stable',
        'cpu': 'stable',
        'render': 'stable',
        'network': 'stable'
      };
    }

    final memoryTrend = _calculateTrend(
      older.map((s) => s.memoryInfo.usagePercentage).reduce((a, b) => a + b) /
          older.length,
      recent.map((s) => s.memoryInfo.usagePercentage).reduce((a, b) => a + b) /
          recent.length,
    );

    final cpuTrend = _calculateTrend(
      older.map((s) => s.cpuInfo.usage).reduce((a, b) => a + b) / older.length,
      recent.map((s) => s.cpuInfo.usage).reduce((a, b) => a + b) /
          recent.length,
    );

    final renderTrend = _calculateTrend(
      older.map((s) => s.renderInfo.frameRate).reduce((a, b) => a + b) /
          older.length,
      recent.map((s) => s.renderInfo.frameRate).reduce((a, b) => a + b) /
          recent.length,
    );

    final networkTrend = _calculateTrend(
      older.map((s) => s.networkInfo.latency).reduce((a, b) => a + b) /
          older.length,
      recent.map((s) => s.networkInfo.latency).reduce((a, b) => a + b) /
          recent.length,
    );

    return {
      'memory': memoryTrend,
      'cpu': cpuTrend,
      'render': renderTrend,
      'network': networkTrend,
    };
  }

  String _calculateTrend(double older, double recent) {
    final difference = recent - older;
    final threshold = older * 0.1; // 10% threshold

    if (difference > threshold) {
      return 'increasing';
    } else if (difference < -threshold) {
      return 'decreasing';
    } else {
      return 'stable';
    }
  }

  /// Clear all data
  void clearData() {
    _snapshots.clear();
    _alerts.clear();
    _memoryHistory.clear();
    _cpuHistory.clear();
    _networkHistory.clear();
    _renderHistory.clear();
    _profileSessions.clear();
    _profileData.clear();

    for (final metric in _metrics.values) {
      metric.dataPoints.clear();
    }
  }

  /// Export performance data
  Future<String> exportData() async {
    final data = {
      'exportTime': DateTime.now().toIso8601String(),
      'systemInfo': _systemInfo,
      'packageInfo': _packageInfo?.toMap(),
      'snapshots': _snapshots.map((s) => s.toMap()).toList(),
      'alerts': _alerts.map((a) => a.toMap()).toList(),
      'metrics': _metrics.map((k, v) => MapEntry(k, v.toMap())),
    };

    return jsonEncode(data);
  }

  /// Dispose performance monitor
  void dispose() {
    stopMonitoring();
    clearData();
    _isInitialized = false;
  }
}

// Performance Models
class PerformanceSnapshot {
  final DateTime timestamp;
  final MemoryInfo memoryInfo;
  final CPUInfo cpuInfo;
  final NetworkInfo networkInfo;
  final RenderInfo renderInfo;

  const PerformanceSnapshot({
    required this.timestamp,
    required this.memoryInfo,
    required this.cpuInfo,
    required this.networkInfo,
    required this.renderInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'memoryInfo': memoryInfo.toMap(),
      'cpuInfo': cpuInfo.toMap(),
      'networkInfo': networkInfo.toMap(),
      'renderInfo': renderInfo.toMap(),
    };
  }
}

class MemoryInfo {
  final double totalMemory;
  final double usedMemory;
  final double freeMemory;
  final double usagePercentage;
  final DateTime timestamp;

  const MemoryInfo({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
    required this.usagePercentage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalMemory': totalMemory,
      'usedMemory': usedMemory,
      'freeMemory': freeMemory,
      'usagePercentage': usagePercentage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class CPUInfo {
  final double usage;
  final int cores;
  final double frequency;
  final double temperature;
  final DateTime timestamp;

  const CPUInfo({
    required this.usage,
    required this.cores,
    required this.frequency,
    required this.temperature,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'usage': usage,
      'cores': cores,
      'frequency': frequency,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class NetworkInfo {
  final bool isConnected;
  final double latency;
  final double bandwidth;
  final String connectionType;
  final DateTime timestamp;

  const NetworkInfo({
    required this.isConnected,
    required this.latency,
    required this.bandwidth,
    required this.connectionType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'isConnected': isConnected,
      'latency': latency,
      'bandwidth': bandwidth,
      'connectionType': connectionType,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class RenderInfo {
  final double frameRate;
  final double frameTime;
  final int droppedFrames;
  final double rasterTime;
  final double uiTime;
  final DateTime timestamp;

  const RenderInfo({
    required this.frameRate,
    required this.frameTime,
    required this.droppedFrames,
    required this.rasterTime,
    required this.uiTime,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'frameRate': frameRate,
      'frameTime': frameTime,
      'droppedFrames': droppedFrames,
      'rasterTime': rasterTime,
      'uiTime': uiTime,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PerformanceMetric {
  final String name;
  final MetricType type;
  final String unit;
  double currentValue;
  double averageValue;
  double minValue;
  double maxValue;
  final List<PerformanceDataPoint> dataPoints;

  PerformanceMetric({
    required this.name,
    required this.type,
    required this.unit,
    required this.currentValue,
    required this.averageValue,
    required this.minValue,
    required this.maxValue,
    required this.dataPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'unit': unit,
      'currentValue': currentValue,
      'averageValue': averageValue,
      'minValue': minValue,
      'maxValue': maxValue,
      'dataPointsCount': dataPoints.length,
    };
  }
}

class PerformanceDataPoint {
  final DateTime timestamp;
  final double value;

  const PerformanceDataPoint({
    required this.timestamp,
    required this.value,
  });
}

class PerformanceThreshold {
  final String name;
  final double warningThreshold;
  final double criticalThreshold;
  final String unit;
  final String description;

  const PerformanceThreshold({
    required this.name,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.unit,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'warningThreshold': warningThreshold,
      'criticalThreshold': criticalThreshold,
      'unit': unit,
      'description': description,
    };
  }
}

class PerformanceAlert {
  final String id;
  final AlertType type;
  final String metric;
  final String message;
  final double value;
  final double threshold;
  final DateTime timestamp;

  const PerformanceAlert({
    required this.id,
    required this.type,
    required this.metric,
    required this.message,
    required this.value,
    required this.threshold,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'metric': metric,
      'message': message,
      'value': value,
      'threshold': threshold,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ProfileSession {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;

  const ProfileSession({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  ProfileSession copyWith({
    DateTime? endTime,
    Duration? duration,
  }) {
    return ProfileSession(
      id: id,
      name: name,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
    };
  }
}

class ProfileData {
  final String operation;
  final Duration duration;
  final DateTime timestamp;

  const ProfileData({
    required this.operation,
    required this.duration,
    required this.timestamp,
  });
}

// History snapshots
class MemorySnapshot extends MemoryInfo {
  const MemorySnapshot({
    required super.totalMemory,
    required super.usedMemory,
    required super.freeMemory,
    required super.usagePercentage,
    required super.timestamp,
  });
}

class CPUSnapshot extends CPUInfo {
  const CPUSnapshot({
    required super.usage,
    required super.cores,
    required super.frequency,
    required super.temperature,
    required super.timestamp,
  });
}

class NetworkSnapshot extends NetworkInfo {
  const NetworkSnapshot({
    required super.isConnected,
    required super.latency,
    required super.bandwidth,
    required super.connectionType,
    required super.timestamp,
  });
}

class RenderSnapshot extends RenderInfo {
  const RenderSnapshot({
    required super.frameRate,
    required super.frameTime,
    required super.droppedFrames,
    required super.rasterTime,
    required super.uiTime,
    required super.timestamp,
  });
}

// Enums
enum MetricType {
  memory,
  cpu,
  network,
  render,
  storage,
}

enum AlertType {
  info,
  warning,
  critical,
}

// Extensions
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}
