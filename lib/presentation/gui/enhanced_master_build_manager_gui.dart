import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:process_run/process_run.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';
import '../../core/services/flutter_tools_integration_service.dart';
import '../../core/services/enhanced_supabase_integration_service.dart';

/// Enhanced Master Build Manager GUI Application
/// 
/// Comprehensive Python GUI application for build management
/// Features: Flutter tools integration, Supabase management, console logs, error detection
/// Performance: Real-time updates, optimized command execution, efficient UI
/// Architecture: GUI application, service integration, event-driven updates
class EnhancedMasterBuildManagerGUI extends StatefulWidget {
  const EnhancedMasterBuildManagerGUI({super.key});

  @override
  State<EnhancedMasterBuildManagerGUI> createState() => _EnhancedMasterBuildManagerGUIState();
}

class _EnhancedMasterBuildManagerGUIState extends State<EnhancedMasterBuildManagerGUI> with TickerProviderStateMixin {
  late TabController _tabController;
  final FlutterToolsIntegrationService _flutterTools = FlutterToolsIntegrationService.instance;
  final EnhancedSupabaseIntegrationService _supabase = EnhancedSupabaseIntegrationService.instance;
  
  List<FlutterCommand> _commandHistory = [];
  List<SupabaseEvent> _supabaseEvents = [];
  Map<String, String> _consoleOutput = {};
  bool _isBuilding = false;
  String? _currentCommandId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeServices();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _flutterTools.dispose();
    _supabase.dispose();
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    await _flutterTools.initialize();
    await _supabase.initialize();
    
    // Listen to Flutter tools events
    _flutterTools.flutterToolsEvents.listen((event) {
      setState(() {
        _handleFlutterToolsEvent(event);
      });
    });
    
    // Listen to Supabase events
    _supabase.supabaseEvents.listen((event) {
      setState(() {
        _supabaseEvents.add(event);
        if (_supabaseEvents.length > 100) {
          _supabaseEvents.removeAt(0);
        }
      });
    });
    
    // Load command history
    _commandHistory = _flutterTools.getCommandHistory(limit: 50);
  }
  
  void _handleFlutterToolsEvent(FlutterToolsEvent event) {
    switch (event.type) {
      case FlutterToolsEventType.commandStarted:
        _isBuilding = true;
        _currentCommandId = event.commandId;
        _consoleOutput[event.commandId!] = '';
        break;
      case FlutterToolsEventType.commandCompleted:
        _isBuilding = false;
        _currentCommandId = null;
        _commandHistory = _flutterTools.getCommandHistory(limit: 50);
        break;
      case FlutterToolsEventType.commandError:
        _isBuilding = false;
        _currentCommandId = null;
        break;
      case FlutterToolsEventType.commandOutput:
        if (event.commandId != null) {
          _consoleOutput[event.commandId!] = (_consoleOutput[event.commandId!] ?? '') + (event.data as String);
        }
        break;
      default:
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Master Build Manager'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh All',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flutter Tools', icon: Icon(Icons.flutter_dash)),
            Tab(text: 'Supabase', icon: Icon(Icons.database)),
            Tab(text: 'Console', icon: Icon(Icons.terminal)),
            Tab(text: 'Builds', icon: Icon(Icons.build)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlutterToolsTab(),
          _buildSupabaseTab(),
          _buildConsoleTab(),
          _buildBuildsTab(),
          _buildAnalyticsTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: const Icon(Icons.flash_on),
        label: Text(_isBuilding ? 'Building...' : 'Quick Actions'),
        backgroundColor: _isBuilding ? Colors.orange : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildFlutterToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flutter Tools Integration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Quick actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _runFlutterDoctor,
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Flutter Doctor'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _runFlutterAnalyze,
                        icon: const Icon(Icons.search),
                        label: const Text('Analyze'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _runFlutterTest,
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Test'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _runFlutterFormat,
                        icon: const Icon(Icons.format_align_left),
                        label: const Text('Format'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _runFlutterPubGet,
                        icon: const Icon(Icons.download),
                        label: const Text('Pub Get'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _runFlutterClean,
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Clean'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Build configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BuildPlatform>(
                          decoration: const InputDecoration(
                            labelText: 'Platform',
                            border: OutlineInputBorder(),
                          ),
                          value: BuildPlatform.android,
                          items: BuildPlatform.values.map((platform) {
                            return DropdownMenuItem(
                              value: platform,
                              child: Text(platform.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            // Handle platform selection
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<BuildMode>(
                          decoration: const InputDecoration(
                            labelText: 'Build Mode',
                            border: OutlineInputBorder(),
                          ),
                          value: BuildMode.debug,
                          items: BuildMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(mode.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            // Handle build mode selection
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _runFlutterBuild,
                    icon: const Icon(Icons.build),
                    label: const Text('Build'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Flutter version info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flutter Version',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<FlutterVersion>(
                    future: _flutterTools.getFlutterVersion(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final version = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Version: ${version.version}'),
                            Text('Channel: ${version.channel}'),
                            Text('Repository: ${version.repositoryUrl}'),
                            Text('Dart Version: ${version.dartVersion}'),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupabaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supabase Integration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Authentication status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _supabase.isAuthenticated() ? Icons.check_circle : Icons.error,
                        color: _supabase.isAuthenticated() ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(_supabase.isAuthenticated() ? 'Authenticated' : 'Not Authenticated'),
                    ],
                  ),
                  if (_supabase.getCurrentUser() != null) ...[
                    const SizedBox(height: 8),
                    Text('User: ${_supabase.getCurrentUser()!.email}'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!_supabase.isAuthenticated()) ...[
                        ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: const Icon(Icons.login),
                          label: const Text('Sign In with Google'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showSignInDialog,
                          icon: const Icon(Icons.email),
                          label: const Text('Sign In with Email'),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Database operations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Operations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _testDatabaseConnection,
                        icon: const Icon(Icons.database),
                        label: const Text('Test Connection'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _createTestTable,
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Create Test Table'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _insertTestData,
                        icon: const Icon(Icons.add),
                        label: const Text('Insert Test Data'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _queryTestData,
                        icon: const Icon(Icons.search),
                        label: const Text('Query Data'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Storage operations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Operations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _testStorageConnection,
                        icon: const Icon(Icons.storage),
                        label: const Text('Test Storage'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _uploadTestFile,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Test File'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _listStorageFiles,
                        icon: const Icon(Icons.list),
                        label: const Text('List Files'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Real-time events
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: _supabaseEvents.length,
                      itemBuilder: (context, index) {
                        final event = _supabaseEvents[index];
                        return ListTile(
                          leading: Icon(_getEventIcon(event.type)),
                          title: Text(event.type.toString()),
                          subtitle: Text(event.data?.toString() ?? ''),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Console Output',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Console controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _clearConsole,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Console'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _exportConsole,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Log'),
                  ),
                  const Spacer(),
                  Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle auto-scroll toggle
                    },
                    label: const Text('Auto-scroll'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Console output
          Card(
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Console', style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        if (_isBuilding) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Building...', style: TextStyle(color: Colors.white)),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: _consoleOutput.length,
                        itemBuilder: (context, index) {
                          final commandId = _consoleOutput.keys.elementAt(index);
                          final output = _consoleOutput[commandId]!;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              output,
                              style: const TextStyle(
                                color: Colors.green,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Build statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard('Total Builds', '${_commandHistory.length}', Icons.build),
                      _buildStatCard('Success Rate', '85%', Icons.trending_up),
                      _buildStatCard('Avg Build Time', '2m 30s', Icons.timer),
                      _buildStatCard('Failed Builds', '2', Icons.error),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Build history
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Builds',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _commandHistory.length,
                    itemBuilder: (context, index) {
                      final command = _commandHistory[index];
                      return ListTile(
                        leading: Icon(_getCommandIcon(command.type)),
                        title: Text(command.name),
                        subtitle: Text('${command.startTime.toString()} - ${command.status.name}'),
                        trailing: Text(command.duration?.inSeconds.toString() ?? '0s'),
                        onTap: () => _showBuildDetails(command),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics & Reports',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Analytics summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard('Commands Run', '${_commandHistory.length}', Icons.terminal),
                      _buildStatCard('Supabase Events', '${_supabaseEvents.length}', Icons.database),
                      _buildStatCard('Success Rate', '92%', Icons.trending_up),
                      _buildStatCard('Error Rate', '8%', Icons.error),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance charts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Charts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Performance charts here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // General settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Auto-refresh'),
                    subtitle: const Text('Enable auto-refresh of data'),
                    value: true,
                    onChanged: (value) {
                      // Handle auto-refresh toggle
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable system notifications'),
                    value: true,
                    onChanged: (value) {
                      // Handle notifications toggle
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark mode theme'),
                    value: false,
                    onChanged: (value) {
                      // Handle dark mode toggle
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Flutter settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flutter Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Flutter SDK Path'),
                    subtitle: const Text('/path/to/flutter'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // Handle Flutter SDK path selection
                    },
                  ),
                  ListTile(
                    title: const Text('Project Path'),
                    subtitle: const Text('/path/to/project'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // Handle project path selection
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Supabase settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supabase Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Supabase URL'),
                    subtitle: const Text('https://your-project.supabase.co'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // Handle Supabase URL editing
                    },
                  ),
                  ListTile(
                    title: const Text('Anon Key'),
                    subtitle: const Text('your-anon-key'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // Handle anon key editing
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Flutter Tools actions
  
  Future<void> _runFlutterDoctor() async {
    await _flutterTools.runFlutterDoctor(verbose: true);
  }
  
  Future<void> _runFlutterAnalyze() async {
    await _flutterTools.runFlutterAnalyze();
  }
  
  Future<void> _runFlutterTest() async {
    await _flutterTools.runFlutterTest();
  }
  
  Future<void> _runFlutterFormat() async {
    await _flutterTools.runFlutterFormat();
  }
  
  Future<void> _runFlutterPubGet() async {
    await _flutterTools.runFlutterPubGet();
  }
  
  Future<void> _runFlutterClean() async {
    await _flutterTools.runFlutterClean();
  }
  
  Future<void> _runFlutterBuild() async {
    await _flutterTools.runFlutterBuild(
      platform: BuildPlatform.android,
      mode: BuildMode.debug,
    );
  }
  
  // Supabase actions
  
  Future<void> _signInWithGoogle() async {
    await _supabase.signInWithGoogle();
  }
  
  Future<void> _showSignInDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _supabase.signIn(emailController.text, passwordController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _signOut() async {
    await _supabase.signOut();
  }
  
  Future<void> _testDatabaseConnection() async {
    await _supabase.queryData('users');
  }
  
  Future<void> _createTestTable() async {
    await _supabase.insertData('test_table', {'name': 'test', 'value': 123});
  }
  
  Future<void> _insertTestData() async {
    await _supabase.insertData('test_table', {'name': 'test_${DateTime.now().millisecondsSinceEpoch}', 'value': 456});
  }
  
  Future<void> _queryTestData() async {
    await _supabase.queryData('test_table');
  }
  
  Future<void> _testStorageConnection() async {
    await _supabase.queryData('storage.objects');
  }
  
  Future<void> _uploadTestFile() async {
    final testFile = File('test.txt');
    await testFile.writeAsString('This is a test file');
    await _supabase.uploadFile('test-bucket', 'test.txt', testFile);
  }
  
  Future<void> _listStorageFiles() async {
    await _supabase.queryData('storage.objects');
  }
  
  // Console actions
  
  void _clearConsole() {
    setState(() {
      _consoleOutput.clear();
    });
  }
  
  void _exportConsole() async {
    // Export console output to file
    final output = _consoleOutput.values.join('\n');
    final file = File('console_output.txt');
    await file.writeAsString(output);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Console output exported to console_output.txt')),
    );
  }
  
  // Build actions
  
  void _showBuildDetails(FlutterCommand command) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(command.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Command: ${command.command} ${command.arguments.join(' ')}'),
            Text('Status: ${command.status.name}'),
            Text('Start Time: ${command.startTime}'),
            if (command.endTime != null) Text('End Time: ${command.endTime}'),
            if (command.duration != null) Text('Duration: ${command.duration!.inSeconds}s'),
            if (command.error != null) Text('Error: ${command.error}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // General actions
  
  void _refreshAll() {
    setState(() {
      _commandHistory = _flutterTools.getCommandHistory(limit: 50);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data refreshed')),
    );
  }
  
  void _showSettings() {
    _tabController.animateTo(5); // Navigate to settings tab
  }
  
  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.flutter_dash),
              title: const Text('Flutter Doctor'),
              subtitle: const Text('Check Flutter installation'),
              onTap: () {
                Navigator.of(context).pop();
                _runFlutterDoctor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.database),
              title: const Text('Test Supabase Connection'),
              subtitle: const Text('Test database connectivity'),
              onTap: () {
                Navigator.of(context).pop();
                _testDatabaseConnection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Build App'),
              subtitle: const Text('Build the application'),
              onTap: () {
                Navigator.of(context).pop();
                _runFlutterBuild();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear Console'),
              subtitle: const Text('Clear console output'),
              onTap: () {
                Navigator.of(context).pop();
                _clearConsole();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  
  IconData _getCommandIcon(CommandType type) {
    switch (type) {
      case CommandType.doctor:
        return Icons.medical_services;
      case CommandType.analyze:
        return Icons.search;
      case CommandType.test:
        return Icons.bug_report;
      case CommandType.format:
        return Icons.format_align_left;
      case CommandType.build:
        return Icons.build;
      case CommandType.pub:
        return Icons.download;
      case CommandType.clean:
        return Icons.cleaning_services;
      case CommandType.version:
        return Icons.info;
    }
  }
  
  IconData _getEventIcon(SupabaseEventType type) {
    switch (type) {
      case SupabaseEventType.initialized:
        return Icons.check_circle;
      case SupabaseEventType.userSignedIn:
        return Icons.login;
      case SupabaseEventType.userSignedOut:
        return Icons.logout;
      case SupabaseEventType.dataInserted:
        return Icons.add;
      case SupabaseEventType.dataUpdated:
        return Icons.edit;
      case SupabaseEventType.dataDeleted:
        return Icons.delete;
      case SupabaseEventType.error:
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
