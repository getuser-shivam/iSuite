import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:process_run/process_run.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Flutter Tools Integration Service
/// 
/// Comprehensive Flutter tools integration with advanced features
/// Features: Flutter doctor, analyze, test, format, build, pub commands
/// Performance: Optimized command execution, real-time output, error handling
/// Architecture: Service layer, async operations, command abstraction
class FlutterToolsIntegrationService {
  static FlutterToolsIntegrationService? _instance;
  static FlutterToolsIntegrationService get instance => _instance ??= FlutterToolsIntegrationService._internal();
  
  FlutterToolsIntegrationService._internal();
  
  final Map<String, FlutterCommand> _commands = {};
  final Map<String, CommandResult> _results = {};
  final StreamController<FlutterToolsEvent> _eventController = StreamController.broadcast();
  final Map<String, Process> _processes = {};
  
  Stream<FlutterToolsEvent> get flutterToolsEvents => _eventController.stream;
  
  /// Initialize Flutter tools
  Future<void> initialize() async {
    await _checkFlutterInstallation();
    await _loadFlutterCommands();
    await _initializeCommandHistory();
  }
  
  /// Run Flutter doctor
  Future<CommandResult> runFlutterDoctor({bool verbose = false}) async {
    final commandId = _generateCommandId();
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Doctor',
      command: 'flutter',
      arguments: ['doctor'] + (verbose ? ['-v'] : []),
      type: CommandType.doctor,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Run Flutter analyze
  Future<CommandResult> runFlutterAnalyze({String? path, List<String>? options}) async {
    final commandId = _generateCommandId();
    final arguments = ['analyze'];
    
    if (path != null) {
      arguments.add(path);
    }
    
    if (options != null) {
      arguments.addAll(options);
    }
    
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Analyze',
      command: 'flutter',
      arguments: arguments,
      type: CommandType.analyze,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Run Flutter test
  Future<CommandResult> runFlutterTest({String? path, List<String>? options}) async {
    final commandId = _generateCommandId();
    final arguments = ['test'];
    
    if (path != null) {
      arguments.add(path);
    }
    
    if (options != null) {
      arguments.addAll(options);
    }
    
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Test',
      command: 'flutter',
      arguments: arguments,
      type: CommandType.test,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Run Flutter format
  Future<CommandResult> runFlutterFormat({String? path, List<String>? options}) async {
    final commandId = _generateCommandId();
    final arguments = ['format'];
    
    if (path != null) {
      arguments.add(path);
    }
    
    if (options != null) {
      arguments.addAll(options);
    }
    
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Format',
      command: 'flutter',
      arguments: arguments,
      type: CommandType.format,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Run Flutter build
  Future<CommandResult> runFlutterBuild({
    required BuildPlatform platform,
    BuildMode mode = BuildMode.debug,
    String? outputPath,
    List<String>? options,
  }) async {
    final commandId = _generateCommandId();
    final arguments = ['build'];
    
    switch (platform) {
      case BuildPlatform.android:
        arguments.add('apk');
        break;
      case BuildPlatform.ios:
        arguments.add('ios');
        break;
      case BuildPlatform.web:
        arguments.add('web');
        break;
      case BuildPlatform.windows:
        arguments.add('windows');
        break;
      case BuildPlatform.linux:
        arguments.add('linux');
        break;
      case BuildPlatform.macos:
        arguments.add('macos');
        break;
    }
    
    if (mode == BuildMode.release) {
      arguments.add('--release');
    }
    
    if (outputPath != null) {
      arguments.addAll(['--output-path', outputPath]);
    }
    
    if (options != null) {
      arguments.addAll(options);
    }
    
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Build ${platform.name}',
      command: 'flutter',
      arguments: arguments,
      type: CommandType.build,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Run Flutter pub get
  Future<CommandResult> runFlutterPubGet() async {
    final commandId = _generateCommandId();
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Pub Get',
      command: 'flutter',
      arguments: ['pub', 'get'],
      type: CommandType.pub,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Run Flutter clean
  Future<CommandResult> runFlutterClean() async {
    final commandId = _generateCommandId();
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Clean',
      command: 'flutter',
      arguments: ['clean'],
      type: CommandType.clean,
      startTime: DateTime.now(),
    );
    
    _commands[commandId] = command;
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandStarted, commandId: commandId));
    
    try {
      final result = await _executeCommand(command);
      _results[commandId] = result;
      
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCompleted, commandId: commandId, data: result));
      
      return result;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Get Flutter version
  Future<FlutterVersion> getFlutterVersion() async {
    final commandId = _generateCommandId();
    final command = FlutterCommand(
      id: commandId,
      name: 'Flutter Version',
      command: 'flutter',
      arguments: ['--version'],
      type: CommandType.version,
      startTime: DateTime.now(),
    );
    
    try {
      final result = await _executeCommand(command);
      final versionOutput = result.output.trim();
      
      // Parse version information
      final version = _parseFlutterVersion(versionOutput);
      
      return version;
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandError, commandId: commandId, error: e.toString()));
      rethrow;
    }
  }
  
  /// Get command status
  FlutterCommand? getCommandStatus(String commandId) {
    return _commands[commandId];
  }
  
  /// Get command result
  CommandResult? getCommandResult(String commandId) {
    return _results[commandId];
  }
  
  /// Cancel command
  Future<void> cancelCommand(String commandId) async {
    final process = _processes[commandId];
    if (process != null) {
      process.kill();
      _processes.remove(commandId);
      
      final command = _commands[commandId];
      if (command != null) {
        command.status = CommandStatus.cancelled;
        command.endTime = DateTime.now();
        
        _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.commandCancelled, commandId: commandId));
      }
    }
  }
  
  /// Get command history
  List<FlutterCommand> getCommandHistory({int? limit}) {
    var commands = _commands.values.toList();
    commands.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    if (limit != null) {
      commands = commands.take(limit).toList();
    }
    
    return commands;
  }
  
  /// Clear command history
  void clearCommandHistory() {
    _commands.clear();
    _results.clear();
    _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.historyCleared));
  }
  
  // Private methods
  
  Future<void> _checkFlutterInstallation() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('Flutter is not installed or not in PATH');
      }
    } catch (e) {
      _emitEvent(FlutterToolsEvent(type: FlutterToolsEventType.flutterNotInstalled, error: e.toString()));
      rethrow;
    }
  }
  
  Future<void> _loadFlutterCommands() async {
    // Load predefined Flutter commands
    final commands = [
      FlutterCommand(
        id: 'doctor',
        name: 'Flutter Doctor',
        command: 'flutter',
        arguments: ['doctor'],
        type: CommandType.doctor,
        startTime: DateTime.now(),
      ),
      FlutterCommand(
        id: 'analyze',
        name: 'Flutter Analyze',
        command: 'flutter',
        arguments: ['analyze'],
        type: CommandType.analyze,
        startTime: DateTime.now(),
      ),
      FlutterCommand(
        id: 'test',
        name: 'Flutter Test',
        command: 'flutter',
        arguments: ['test'],
        type: CommandType.test,
        startTime: DateTime.now(),
      ),
      FlutterCommand(
        id: 'format',
        name: 'Flutter Format',
        command: 'flutter',
        arguments: ['format'],
        type: CommandType.format,
        startTime: DateTime.now(),
      ),
      FlutterCommand(
        id: 'pub_get',
        name: 'Flutter Pub Get',
        command: 'flutter',
        arguments: ['pub', 'get'],
        type: CommandType.pub,
        startTime: DateTime.now(),
      ),
      FlutterCommand(
        id: 'clean',
        name: 'Flutter Clean',
        command: 'flutter',
        arguments: ['clean'],
        type: CommandType.clean,
        startTime: DateTime.now(),
      ),
    ];
    
    for (final command in commands) {
      _commands[command.id] = command;
    }
  }
  
  Future<void> _initializeCommandHistory() async {
    // Initialize command history from storage
  }
  
  Future<CommandResult> _executeCommand(FlutterCommand command) async {
    final startTime = DateTime.now();
    final output = <String>[];
    final errorOutput = <String>[];
    
    try {
      command.status = CommandStatus.running;
      
      final process = await Process.start(
        command.command,
        command.arguments,
        workingDirectory: Directory.current.path,
      );
      
      _processes[command.id] = process;
      
      // Listen to stdout
      process.stdout.transform(utf8.decoder).listen((data) {
        output.add(data);
        _emitEvent(FlutterToolsEvent(
          type: FlutterToolsEventType.commandOutput,
          commandId: command.id,
          data: data,
        ));
      });
      
      // Listen to stderr
      process.stderr.transform(utf8.decoder).listen((data) {
        errorOutput.add(data);
        _emitEvent(FlutterToolsEvent(
          type: FlutterToolsEventType.commandError,
          commandId: command.id,
          error: data,
        ));
      });
      
      // Wait for process to complete
      final exitCode = await process.exitCode;
      
      command.status = exitCode == 0 ? CommandStatus.completed : CommandStatus.failed;
      command.endTime = DateTime.now();
      
      _processes.remove(command.id);
      
      final result = CommandResult(
        commandId: command.id,
        exitCode: exitCode,
        output: output.join('\n'),
        errorOutput: errorOutput.join('\n'),
        duration: DateTime.now().difference(startTime),
        success: exitCode == 0,
      );
      
      return result;
    } catch (e) {
      command.status = CommandStatus.failed;
      command.endTime = DateTime.now();
      command.error = e.toString();
      
      _processes.remove(command.id);
      
      final result = CommandResult(
        commandId: command.id,
        exitCode: -1,
        output: output.join('\n'),
        errorOutput: errorOutput.join('\n'),
        duration: DateTime.now().difference(startTime),
        success: false,
        error: e.toString(),
      );
      
      return result;
    }
  }
  
  FlutterVersion _parseFlutterVersion(String versionOutput) {
    // Parse Flutter version output
    // Example: "Flutter 3.16.0 • channel stable • https://github.com/flutter/flutter.git"
    final lines = versionOutput.split('\n');
    final versionLine = lines.first;
    final parts = versionLine.split(' ');
    
    final version = parts.length > 1 ? parts[1] : 'Unknown';
    final channel = parts.length > 3 ? parts[3] : 'Unknown';
    
    return FlutterVersion(
      version: version,
      channel: channel,
      repositoryUrl: 'https://github.com/flutter/flutter.git',
      frameworkRevision: 'Unknown',
      engineRevision: 'Unknown',
      dartVersion: 'Unknown',
      devToolsVersion: 'Unknown',
    );
  }
  
  String _generateCommandId() {
    return 'cmd_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  void _emitEvent(FlutterToolsEvent event) {
    _eventController.add(event);
  }
  
  void dispose() {
    _eventController.close();
    
    // Cancel all running processes
    for (final process in _processes.values) {
      process.kill();
    }
    _processes.clear();
  }
}

// Model classes

class FlutterCommand {
  final String id;
  final String name;
  final String command;
  final List<String> arguments;
  final CommandType type;
  final DateTime startTime;
  DateTime? endTime;
  CommandStatus status;
  String? error;
  
  FlutterCommand({
    required this.id,
    required this.name,
    required this.command,
    required this.arguments,
    required this.type,
    required this.startTime,
    this.endTime,
    this.status = CommandStatus.pending,
    this.error,
  });
  
  FlutterCommand copyWith({
    String? id,
    String? name,
    String? command,
    List<String>? arguments,
    CommandType? type,
    DateTime? startTime,
    DateTime? endTime,
    CommandStatus? status,
    String? error,
  }) {
    return FlutterCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      arguments: arguments ?? this.arguments,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

class CommandResult {
  final String commandId;
  final int exitCode;
  final String output;
  final String errorOutput;
  final Duration duration;
  final bool success;
  final String? error;
  
  CommandResult({
    required this.commandId,
    required this.exitCode,
    required this.output,
    required this.errorOutput,
    required this.duration,
    required this.success,
    this.error,
  });
}

class FlutterVersion {
  final String version;
  final String channel;
  final String repositoryUrl;
  final String frameworkRevision;
  final String engineRevision;
  final String dartVersion;
  final String devToolsVersion;
  
  FlutterVersion({
    required this.version,
    required this.channel,
    required this.repositoryUrl,
    required this.frameworkRevision,
    required this.engineRevision,
    required this.dartVersion,
    required this.devToolsVersion,
  });
}

class FlutterToolsEvent {
  final FlutterToolsEventType type;
  final String? commandId;
  final dynamic data;
  final String? error;
  
  FlutterToolsEvent({
    required this.type,
    this.commandId,
    this.data,
    this.error,
  });
}

enum CommandType {
  doctor,
  analyze,
  test,
  format,
  build,
  pub,
  clean,
  version,
}

enum CommandStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

enum FlutterToolsEventType {
  commandStarted,
  commandCompleted,
  commandError,
  commandCancelled,
  commandOutput,
  flutterNotInstalled,
  historyCleared,
}

enum BuildPlatform {
  android,
  ios,
  web,
  windows,
  linux,
  macos,
}

enum BuildMode {
  debug,
  release,
  profile,
}
