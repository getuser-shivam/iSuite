import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:io';
import 'dart:async';
import 'package:isuite/features/network_management/ftp_client_service.dart';

// Generate mocks
@GenerateMocks([CentralConfig, LoggingService, Socket])
import 'ftp_client_service_test.mocks.dart';

class MockSocket extends Mock implements Socket {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();
  final List<int> _writtenData = [];

  @override
  Stream<Uint8List> get asBroadcastStream => _controller.stream.asBroadcastStream();

  @override
  Future<void> add(List<int> data) async {
    _writtenData.addAll(data);
  }

  @override
  Future<void> flush() async {
    // Mock flush
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future<bool> any(bool Function(Uint8List element) test) {
    return _controller.stream.any(test);
  }

  @override
  Stream<Uint8List> cast<R>() {
    return _controller.stream.cast<R>();
  }

  @override
  Future<bool> contains(Object? needle) {
    return _controller.stream.contains(needle);
  }

  @override
  Stream<Uint8List> distinct([bool Function(Uint8List previous, Uint8List next)? equals]) {
    return _controller.stream.distinct(equals);
  }

  @override
  Future<Uint8List> elementAt(int index) {
    return _controller.stream.elementAt(index);
  }

  @override
  Future<bool> every(bool Function(Uint8List element) test) {
    return _controller.stream.every(test);
  }

  @override
  Future<Uint8List> firstWhere(bool Function(Uint8List element) test, {Uint8List Function()? orElse}) {
    return _controller.stream.firstWhere(test, orElse: orElse);
  }

  @override
  Future<Uint8List> fold<T>(T initialValue, T Function(T previous, Uint8List element) combine) {
    return _controller.stream.fold(initialValue, combine);
  }

  @override
  Future<dynamic> forEach(void Function(Uint8List element) action) {
    return _controller.stream.forEach(action);
  }

  @override
  Stream<Uint8List> handleError(Function onError, {bool Function(dynamic error)? test}) {
    return _controller.stream.handleError(onError, test: test);
  }

  @override
  Future<bool> isEmpty {
    return _controller.stream.isEmpty;
  }

  @override
  Future<String> join([String separator = ""]) {
    return _controller.stream.join(separator);
  }

  @override
  Future<Uint8List> lastWhere(bool Function(Uint8List element) test, {Uint8List Function()? orElse}) {
    return _controller.stream.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> length {
    return _controller.stream.length;
  }

  @override
  Stream<Uint8List> map<T>(T Function(Uint8List event) convert) {
    return _controller.stream.map(convert);
  }

  @override
  Future<Uint8List> reduce(Uint8List Function(Uint8List previous, Uint8List element) combine) {
    return _controller.stream.reduce(combine);
  }

  @override
  Future<Uint8List> singleWhere(bool Function(Uint8List element) test, {Uint8List Function()? orElse}) {
    return _controller.stream.singleWhere(test, orElse: orElse);
  }

  @override
  Future<List<Uint8List>> toList() {
    return _controller.stream.toList();
  }

  @override
  Future<Set<Uint8List>> toSet() {
    return _controller.stream.toSet();
  }

  @override
  Stream<Uint8List> where(bool Function(Uint8List element) test) {
    return _controller.stream.where(test);
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get isEmpty => _writtenData.isEmpty;

  List<int> get writtenData => _writtenData;

  void simulateData(Uint8List data) {
    _controller.add(data);
  }

  void simulateEnd() {
    _controller.close();
  }

  void simulateError(Object error) {
    _controller.addError(error);
  }
}

void main() {
  late FTPClientService ftpService;
  late MockCentralConfig mockConfig;
  late MockLoggingService mockLogger;

  setUp(() {
    mockConfig = MockCentralConfig();
    mockLogger = MockLoggingService();

    // Reset singleton
    // Note: In a real scenario, you might need to handle singleton reset differently
    ftpService = FTPClientService._internal();
  });

  tearDown(() {
    ftpService.dispose();
  });

  group('FTPClientService - Initialization', () {
    test('should be a singleton', () {
      final instance1 = FTPClientService();
      final instance2 = FTPClientService();
      expect(instance1, equals(instance2));
    });

    test('should initialize with default parameters', () async {
      when(mockConfig.registerComponent(any, any, any, parameters: anyNamed('parameters')))
          .thenAnswer((_) async => {});

      // Note: Testing initialization might require mocking more dependencies
      // This is a basic structure for testing
    });
  });

  group('FTPClientService - Connection Validation', () {
    test('should validate connection parameters correctly', () {
      // Valid parameters
      expect(() => ftpService._validateConnectionParameters('192.168.1.1', 21, 'user', 'pass'),
             returnsNormally);

      // Invalid host
      expect(() => ftpService._validateConnectionParameters('', 21, 'user', 'pass'),
             throwsA(isA<FTPException>()));

      // Invalid port
      expect(() => ftpService._validateConnectionParameters('192.168.1.1', 70000, 'user', 'pass'),
             throwsA(isA<FTPException>()));

      // Invalid username
      expect(() => ftpService._validateConnectionParameters('192.168.1.1', 21, '', 'pass'),
             throwsA(isA<FTPException>()));

      // Invalid password length
      expect(() => ftpService._validateConnectionParameters('192.168.1.1', 21, 'user', 'x' * 300),
             throwsA(isA<FTPException>()));
    });
  });

  group('FTPClientService - Error Handling', () {
    test('should categorize errors correctly', () {
      final errorLines = [
        'Fatal error occurred',
        'Build failed: syntax error',
        'Permission denied',
        'Connection timeout',
        'File not found',
      ];

      final categories = ftpService.categorize_errors(errorLines);

      expect(categories['critical'], equals(1));
      expect(categories['build'], equals(1));
      expect(categories['permission'], equals(1));
      expect(categories['network'], equals(1));
      expect(categories['other'], equals(1));
    });

    test('should categorize individual error lines', () {
      expect(ftpService.categorize_error_line('Fatal crash occurred'), equals('CRITICAL'));
      expect(ftpService.categorize_error_line('Build failed'), equals('BUILD'));
      expect(ftpService.categorize_error_line('Permission denied'), equals('PERM'));
      expect(ftpService.categorize_error_line('Connection failed'), equals('NET'));
      expect(ftpService.categorize_error_line('Unknown error'), equals('OTHER'));
    });

    test('should determine retryable errors correctly', () {
      final ftpException = FTPException('Connection failed', FTPErrorType.connectionFailed);
      expect(ftpService._isRetryableError(ftpException), isTrue);

      final authException = FTPException('Authentication failed', FTPErrorType.authenticationFailed);
      expect(ftpService._isRetryableError(authException), isFalse);

      final networkError = Exception('Network timeout');
      expect(ftpService._isRetryableError(networkError), isTrue);
    });
  });

  group('FTPClientService - Utility Methods', () {
    test('should mask password correctly', () {
      expect(ftpService._maskPassword(''), equals(''));
      expect(ftpService._maskPassword('a'), equals('*'));
      expect(ftpService._maskPassword('ab'), equals('**'));
      expect(ftpService._maskPassword('abc'), equals('a*c'));
      expect(ftpService._maskPassword('abcd'), equals('a**d'));
    });

    test('should generate unique connection IDs', () {
      final id1 = ftpService._generateConnectionId();
      final id2 = ftpService._generateConnectionId();

      expect(id1, isNot(equals(id2)));
      expect(id1.startsWith('ftp_'), isTrue);
      expect(id2.startsWith('ftp_'), isTrue);
    });

    test('should parse passive mode response correctly', () {
      const response = '227 Entering Passive Mode (192,168,1,1,12,34)';
      final result = ftpService._parsePassiveModeResponse(response);

      expect(result.$1.address, equals('192.168.1.1'));
      expect(result.$2, equals(12 * 256 + 34));
    });

    test('should handle malformed passive mode response', () {
      const response = '227 Invalid response';
      expect(() => ftpService._parsePassiveModeResponse(response),
             throwsA(isA<Exception>()));
    });
  });

  group('FTPClientService - Directory Listing Parsing', () {
    test('should parse directory listing correctly', () {
      const listing = '''
drwxr-xr-x 2 user group 4096 Jan 01 12:00 testdir
-rw-r--r-- 1 user group 1024 Jan 01 12:00 testfile.txt
-rw-r--r-- 1 user group 0 Jan 01 12:00 empty.txt
''';

      final files = ftpService._parseDirectoryListing(listing);

      expect(files.length, equals(3));

      expect(files[0].name, equals('testdir'));
      expect(files[0].isDirectory, isTrue);

      expect(files[1].name, equals('testfile.txt'));
      expect(files[1].isDirectory, isFalse);
      expect(files[1].size, equals(1024));

      expect(files[2].name, equals('empty.txt'));
      expect(files[2].isDirectory, isFalse);
      expect(files[2].size, equals(0));
    });

    test('should handle malformed directory listing', () {
      const listing = '''
drwxr-xr-x 2 user group 4096 Jan 01 12:00 testdir
malformed line
-rw-r--r-- 1 user group 1024 Jan 01 12:00 testfile.txt
''';

      final files = ftpService._parseDirectoryListing(listing);

      // Should skip malformed lines
      expect(files.length, equals(2));
    });
  });

  group('FTPClientService - Event Emission', () {
    test('should emit FTP events correctly', () {
      final events = <FTPEvent>[];
      final subscription = ftpService.ftpEvents.listen(events.add);

      ftpService._emitFTPEvent(FTPEventType.connecting, connectionId: 'test_conn');
      ftpService._emitFTPEvent(FTPEventType.connected, connectionId: 'test_conn');

      // Allow events to be processed
      Future.delayed(Duration.zero, () {
        expect(events.length, equals(2));
        expect(events[0].type, equals(FTPEventType.connecting));
        expect(events[0].connectionId, equals('test_conn'));
        expect(events[1].type, equals(FTPEventType.connected));
        expect(events[1].connectionId, equals('test_conn'));
      });

      subscription.cancel();
    });
  });

  group('FTPClientService - Connection Management', () {
    test('should manage active connections correctly', () {
      // Create mock connection
      final mockSocket = MockSocket();
      final connection = FTPConnection(
        id: 'test_conn',
        host: '192.168.1.1',
        port: 21,
        username: 'test',
        socket: mockSocket,
        status: FTPConnectionStatus.ready,
        useSSL: false,
      );

      // Manually add connection for testing
      ftpService._activeConnections['test_conn'] = connection;

      expect(ftpService.getConnection('test_conn'), equals(connection));
      expect(ftpService.getActiveConnections().length, equals(1));

      // Test disconnect
      ftpService.disconnect('test_conn');
      expect(ftpService.getActiveConnections().length, equals(0));
    });

    test('should handle disconnect gracefully', () async {
      final mockSocket = MockSocket();
      final connection = FTPConnection(
        id: 'test_conn',
        host: '192.168.1.1',
        port: 21,
        username: 'test',
        socket: mockSocket,
        status: FTPConnectionStatus.ready,
        useSSL: false,
      );

      ftpService._activeConnections['test_conn'] = connection;

      // Mock socket close to throw exception
      when(mockSocket.close()).thenThrow(Exception('Socket close failed'));

      // Should not throw exception
      await expectLater(ftpService.disconnect('test_conn'), completes);
    });
  });

  group('FTPClientService - Timeout Handling', () {
    test('should handle data connection timeout', () async {
      final mockSocket = MockSocket();
      final completer = Completer<Uint8List>();

      // Simulate timeout scenario
      final timeoutFuture = ftpService._readDataConnectionWithTimeout(mockSocket, timeout: Duration(milliseconds: 100));

      // Don't add data, let it timeout
      await Future.delayed(Duration(milliseconds: 200));

      expect(() => timeoutFuture, throwsA(isA<FTPException>()));
    });

    test('should complete successfully with data', () async {
      final mockSocket = MockSocket();
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final future = ftpService._readDataConnectionWithTimeout(mockSocket, timeout: Duration(seconds: 1));

      // Simulate receiving data
      mockSocket.simulateData(testData);
      mockSocket.simulateEnd();

      final result = await future;
      expect(result, equals(testData));
    });
  });

  group('FTPClientService - FTP Command Handling', () {
    test('should send FTP commands correctly', () async {
      final mockSocket = MockSocket();

      await ftpService._sendFTPCommand(mockSocket, 'USER test\r\n');

      expect(mockSocket.writtenData, equals('USER test\r\n'.codeUnits));
    });

    test('should read FTP response correctly', () async {
      final mockSocket = MockSocket();

      // Simulate FTP response
      final response = '220 Welcome\r\n';
      mockSocket.simulateData(Uint8List.fromList(response.codeUnits));

      final result = await ftpService._readFTPResponse(mockSocket);

      expect(result, equals('220 Welcome'));
    });
  });

  group('FTPClientService - Exception Handling', () {
    test('FTPException should format correctly', () {
      final exception = FTPException('Test error', FTPErrorType.connectionFailed);

      expect(exception.message, equals('Test error'));
      expect(exception.type, equals(FTPErrorType.connectionFailed));
      expect(exception.toString(), equals('FTPException: Test error (connectionFailed)'));
    });

    test('FTPException with details should format correctly', () {
      final exception = FTPException('Test error', FTPErrorType.connectionFailed, 'Extra details');

      expect(exception.details, equals('Extra details'));
      expect(exception.toString(), equals('FTPException: Test error (connectionFailed)'));
    });
  });

  group('FTPClientService - Integration Scenarios', () {
    test('should handle connection validation failure', () {
      // Test with invalid parameters
      expect(() => ftpService.connect(
        host: '',
        port: 21,
        username: 'test',
        password: 'test'
      ), throwsA(isA<FTPException>()));
    });

    test('should handle listDirectory with invalid connection', () async {
      await expectLater(
        ftpService.listDirectory('invalid_conn'),
        throwsA(isA<FTPException>())
      );
    });

    test('should handle downloadFile with invalid connection', () async {
      await expectLater(
        ftpService.downloadFile(
          connectionId: 'invalid_conn',
          remotePath: '/test.txt',
          localPath: '/tmp/test.txt'
        ),
        throwsA(isA<FTPException>())
      );
    });

    test('should handle uploadFile with invalid connection', () async {
      await expectLater(
        ftpService.uploadFile(
          connectionId: 'invalid_conn',
          localPath: '/tmp/test.txt',
          remotePath: '/test.txt'
        ),
        throwsA(isA<FTPException>())
      );
    });
  });

  group('FTPClientService - Memory Management', () {
    test('dispose should clean up resources', () {
      final mockSocket = MockSocket();
      final connection = FTPConnection(
        id: 'test_conn',
        host: '192.168.1.1',
        port: 21,
        username: 'test',
        socket: mockSocket,
        status: FTPConnectionStatus.ready,
        useSSL: false,
      );

      ftpService._activeConnections['test_conn'] = connection;
      ftpService._ftpEventController.add(FTPEvent(
        type: FTPEventType.connected,
        timestamp: DateTime.now(),
        connectionId: 'test_conn'
      ));

      expect(ftpService.getActiveConnections().length, equals(1));

      ftpService.dispose();

      expect(ftpService.getActiveConnections().length, equals(0));
      expect(ftpService.ftpEvents, emitsDone);
    });
  });
}
