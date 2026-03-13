import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/supabase_providers.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Supabase Configuration Screen
/// 
/// Screen for configuring Supabase settings
/// Features: Configuration management, connection testing, status monitoring
/// Performance: Optimized state updates, efficient configuration access
/// Architecture: Consumer widget, provider pattern, responsive design
class SupabaseConfigurationScreen extends ConsumerStatefulWidget {
  const SupabaseConfigurationScreen({super.key});

  @override
  ConsumerState<SupabaseConfigurationScreen> createState() => _SupabaseConfigurationScreenState();
}

class _SupabaseConfigurationScreenState extends ConsumerState<SupabaseConfigurationScreen> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  final _databaseUrlController = TextEditingController();
  final _storageUrlController = TextEditingController();
  final _functionsUrlController = TextEditingController();
  
  bool _enableAuth = true;
  bool _enableRealtime = true;
  bool _enableStorage = true;
  bool _enableFunctions = true;
  int _cacheTimeout = 300;
  int _connectionTimeout = 30;
  
  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    _databaseUrlController.dispose();
    _storageUrlController.dispose();
    _functionsUrlController.dispose();
    super.dispose();
  }

  void _loadConfiguration() {
    final configProvider = ref.read(supabaseConfigurationProvider);
    final config = configProvider.configuration;
    
    _urlController.text = config['url'] ?? '';
    _anonKeyController.text = config['anon_key'] ?? '';
    _databaseUrlController.text = config['database_url'] ?? '';
    _storageUrlController.text = config['storage_url'] ?? '';
    _functionsUrlController.text = config['functions_url'] ?? '';
    _enableAuth = config['enable_auth'] ?? true;
    _enableRealtime = config['enable_realtime'] ?? true;
    _enableStorage = config['enable_storage'] ?? true;
    _enableFunctions = config['enable_functions'] ?? true;
    _cacheTimeout = config['cache_timeout'] ?? 300;
    _connectionTimeout = config['connection_timeout'] ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(supabaseConfigurationProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Supabase Configuration',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfiguration,
            tooltip: 'Save Configuration',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
            tooltip: 'Test Connection',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            _buildStatusSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Basic Configuration
            _buildBasicConfigurationSection(context, l10n),
            
            const SizedBox(height: 24),
            
            // Advanced Configuration
            _buildAdvancedConfigurationSection(context, l10n),
            
            const SizedBox(height: 24),
            
            // Feature Toggles
            _buildFeatureTogglesSection(context, l10n),
            
            const SizedBox(height: 24),
            
            // Connection Test
            _buildConnectionTestSection(context, l10n, configProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  configProvider.isConfigured ? Icons.check_circle : Icons.error,
                  color: configProvider.isConfigured ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  configProvider.isConfigured ? 'Configured' : 'Not Configured',
                  style: TextStyle(
                    color: configProvider.isConfigured ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  configProvider.isConnected ? Icons.check_circle : Icons.error,
                  color: configProvider.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  configProvider.isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    color: configProvider.isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  configProvider.isAuthenticated ? Icons.check_circle : Icons.error,
                  color: configProvider.isAuthenticated ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  configProvider.isAuthenticated ? 'Authenticated' : 'Not Authenticated',
                  style: TextStyle(
                    color: configProvider.isAuthenticated ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (configProvider.configurationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        configProvider.configurationError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (configProvider.connectionError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        configProvider.connectionError!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicConfigurationSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Supabase URL',
                hintText: 'https://your-project.supabase.co',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _anonKeyController,
              decoration: const InputDecoration(
                labelText: 'Anonymous Key',
                hintText: 'your-anon-key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _databaseUrlController,
              decoration: const InputDecoration(
                labelText: 'Database URL',
                hintText: 'https://your-project.supabase.co/rest/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storageUrlController,
              decoration: const InputDecoration(
                labelText: 'Storage URL',
                hintText: 'https://your-project.supabase.co/storage/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _functionsUrlController,
              decoration: const InputDecoration(
                labelText: 'Functions URL',
                hintText: 'https://your-project.supabase.co/functions/v1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedConfigurationSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cache Timeout (seconds)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _cacheTimeout.toString(),
                    onChanged: (value) {
                      _cacheTimeout = int.tryParse(value) ?? 300;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Connection Timeout (seconds)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _connectionTimeout.toString(),
                    onChanged: (value) {
                      _connectionTimeout = int.tryParse(value) ?? 30;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTogglesSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Toggles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Authentication'),
              subtitle: const Text('Enable user authentication features'),
              value: _enableAuth,
              onChanged: (value) {
                setState(() {
                  _enableAuth = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Realtime'),
              subtitle: const Text('Enable real-time subscriptions'),
              value: _enableRealtime,
              onChanged: (value) {
                setState(() {
                  _enableRealtime = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Storage'),
              subtitle: const Text('Enable file storage features'),
              value: _enableStorage,
              onChanged: (value) {
                setState(() {
                  _enableStorage = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Functions'),
              subtitle: const Text('Enable edge functions'),
              value: _enableFunctions,
              onChanged: (value) {
                setState(() {
                  _enableFunctions = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.network_check),
              label: const Text('Test Connection'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            if (configProvider.isConnected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Connection successful',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    final configProvider = ref.read(supabaseConfigurationProvider);
    
    final newConfig = {
      'supabase.url': _urlController.text.trim(),
      'supabase.anon_key': _anonKeyController.text.trim(),
      'supabase.database_url': _databaseUrlController.text.trim(),
      'supabase.storage_url': _storageUrlController.text.trim(),
      'supabase.functions_url': _functionsUrlController.text.trim(),
      'supabase.enable_auth': _enableAuth,
      'supabase.enable_realtime': _enableRealtime,
      'supabase.enable_storage': _enableStorage,
      'supabase.enable_functions': _enableFunctions,
      'supabase.cache_timeout': _cacheTimeout,
      'supabase.connection_timeout': _connectionTimeout,
    };
    
    final success = await configProvider.updateConfiguration(newConfig);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save configuration'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final configProvider = ref.read(supabaseConfigurationProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing connection...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    final success = await configProvider.testConnection();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection test successful'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection test failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Supabase Authentication Screen
/// 
/// Screen for Supabase authentication
/// Features: Sign in, sign up, OAuth, session management
/// Performance: Optimized state updates, efficient authentication
/// Architecture: Consumer widget, provider pattern, responsive design
class SupabaseAuthenticationScreen extends ConsumerStatefulWidget {
  const SupabaseAuthenticationScreen({super.key});

  @override
  ConsumerState<SupabaseAuthenticationScreen> createState() => _SupabaseAuthenticationScreenState();
}

class _SupabaseAuthenticationScreenState extends ConsumerState<SupabaseAuthenticationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSignUp = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = ref.watch(supabaseAuthenticationProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Supabase Authentication',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current User Info
            if (authProvider.currentUser != null) ...[
              _buildUserInfoSection(context, l10n, authProvider),
              const SizedBox(height: 24),
            ],
            
            // Authentication Form
            if (authProvider.currentUser == null) ...[
              _buildAuthenticationForm(context, l10n, authProvider),
              const SizedBox(height: 24),
            ],
            
            // OAuth Buttons
            if (authProvider.currentUser == null) ...[
              _buildOAuthSection(context, l10n, authProvider),
              const SizedBox(height: 24),
            ],
            
            // Sign Out Button
            if (authProvider.currentUser != null) ...[
              _buildSignOutSection(context, l10n, authProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, AppLocalizations l10n, authProvider) {
    final user = authProvider.currentUser!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user.email?.substring(0, 2).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.email ?? 'Unknown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${user.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${user.createdAt?.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (user.userMetadata != null) ...[
              const SizedBox(height: 16),
              Text(
                'Metadata:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...user.userMetadata!.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationForm(BuildContext context, AppLocalizations l10n, authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle between sign in and sign up
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isSignUp = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isSignUp ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isSignUp = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSignUp ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: !_showPassword,
            ),
            const SizedBox(height: 16),
            
            // Confirm password field (sign up only)
            if (_isSignUp) ...[
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: !_showConfirmPassword,
              ),
              const SizedBox(height: 16),
            ],
            
            // Error message
            if (authProvider.authError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.authError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Submit button
            ElevatedButton.icon(
              onPressed: authProvider.isLoading ? null : _submitAuthentication,
              icon: authProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isSignUp ? Icons.person_add : Icons.login),
              label: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOAuthSection(BuildContext context, AppLocalizations l10n, authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Or sign in with',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: authProvider.isLoading ? null : () => _signInWithOAuth(OAuthProvider.google),
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: authProvider.isLoading ? null : () => _signInWithOAuth(OAuthProvider.github),
                    icon: const Icon(Icons.code),
                    label: const Text('GitHub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutSection(BuildContext context, AppLocalizations l10n, authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: authProvider.isLoading ? null : _signOut,
              icon: authProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAuthentication() async {
    final authProvider = ref.read(supabaseAuthenticationProvider);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_isSignUp) {
      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      await authProvider.signUp(email, password);
    } else {
      await authProvider.signIn(email, password);
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final authProvider = ref.read(supabaseAuthenticationProvider);
    await authProvider.signInWithOAuth(provider);
  }

  Future<void> _signOut() async {
    final authProvider = ref.read(supabaseAuthenticationProvider);
    await authProvider.signOut();
  }
}
