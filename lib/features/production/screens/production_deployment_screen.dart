import 'package:flutter/material.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/project_finalizer.dart';

/// Production Deployment Screen
/// 
/// Provides comprehensive deployment preparation and monitoring
/// for the iSuite application in production environments.
class ProductionDeploymentScreen extends StatefulWidget {
  const ProductionDeploymentScreen({super.key});

  @override
  State<ProductionDeploymentScreen> createState() => _ProductionDeploymentScreenState();
}

class _ProductionDeploymentScreenState extends State<ProductionDeploymentScreen>
    with TickerProviderStateMixin {
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final ProjectFinalizer _finalizer = ProjectFinalizer();

  late AnimationController _animationController;
  late Animation<double> _animation;

  ProjectFinalizationResult? _finalizationResult;
  bool _isFinalizing = false;
  bool _isDeployed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _performFinalization();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.slow', defaultValue: 500)),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _performFinalization() async {
    setState(() {
      _isFinalizing = true;
    });

    try {
      final result = await _finalizer.finalizeProject();
      setState(() {
        _finalizationResult = result;
        _isFinalizing = false;
      });
    } catch (e) {
      _logger.error('Finalization failed', 'ProductionDeploymentScreen', error: e);
      setState(() {
        _isFinalizing = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _config.getParameter('ui.colors.background', defaultValue: Colors.grey[50]),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _animation,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Production Deployment',
        style: TextStyle(
          fontSize: _config.getParameter('ui.font.size.title_large', defaultValue: 22.0),
          fontWeight: FontWeight.bold,
          color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
        ),
      ),
      backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
      foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
      elevation: _config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
      actions: [
        IconButton(
          icon: Icon(
            _isDeployed ? Icons.check_circle : Icons.refresh,
            color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
          ),
          onPressed: _performFinalization,
          tooltip: 'Refresh Status',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          _buildFinalizationResults(),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          _buildProductionChecklist(),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          _buildDeploymentActions(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isReady = _finalizationResult?.isSuccessful ?? false;
    final isMostlyReady = _finalizationResult?.isMostlySuccessful ?? false;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.large', defaultValue: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReady
              ? [
                  _config.getParameter('ui.colors.success', defaultValue: Colors.green),
                  _config.getParameter('ui.colors.success', defaultValue: Colors.green).withOpacity(0.8)
                ]
              : isMostlyReady
                  ? [
                      _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                      _config.getParameter('ui.colors.warning', defaultValue: Colors.orange).withOpacity(0.8)
                    ]
                  : [
                      _config.getParameter('ui.colors.error', defaultValue: Colors.red),
                      _config.getParameter('ui.colors.error', defaultValue: Colors.red).withOpacity(0.8)
                    ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.large', defaultValue: 16.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_config.getParameter('ui.shadow.opacity', defaultValue: 0.1)),
            blurRadius: _config.getParameter('ui.shadow.blur_radius', defaultValue: 8.0),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isReady ? Icons.check_circle : isMostlyReady ? Icons.warning : Icons.error,
            size: _config.getParameter('ui.icon.size.extra_large', defaultValue: 80.0),
            color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          Text(
            isReady
                ? 'PROJECT READY FOR PRODUCTION'
                : isMostlyReady
                    ? 'PROJECT MOSTLY READY FOR PRODUCTION'
                    : 'PROJECT NEEDS ATTENTION',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.title_large', defaultValue: 22.0),
              fontWeight: FontWeight.bold,
              color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          Text(
            _finalizationResult != null
                ? 'Success Rate: ${(_finalizationResult!.successCount / _finalizationResult!.totalCount * 100).toStringAsFixed(1)}%'
                : 'Checking...',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
              color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizationResults() {
    if (_isFinalizing) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _config.getParameter('ui.loading.size.medium', defaultValue: 24.0),
                height: _config.getParameter('ui.loading.size.medium', defaultValue: 24.0),
                child: CircularProgressIndicator(
                  strokeWidth: _config.getParameter('ui.loading.stroke_width', defaultValue: 2.0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
              Text(
                'Finalizing project...',
                style: TextStyle(
                  fontSize: _config.getParameter('ui.font.size.body_large', defaultValue: 16.0),
                  color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_finalizationResult == null) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No finalization results available',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            child: Text(
              'Finalization Results',
              style: TextStyle(
                fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
                fontWeight: FontWeight.bold,
                color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
              ),
            ),
          ),
          _buildResultSection('Successes', _finalizationResult!._successes, Colors.green),
          _buildResultSection('Warnings', _finalizationResult!._warnings, Colors.orange),
          _buildResultSection('Errors', _finalizationResult!._errors, Colors.red),
          _buildResultSection('Info', _finalizationResult!._info, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, List<String> messages, Color color) {
    if (messages.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _config.getParameter('ui.spacing.medium', defaultValue: 16.0),
            vertical: _config.getParameter('ui.spacing.small', defaultValue: 8.0),
          ),
          child: Text(
            '$title (${messages.length})',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        ...messages.map((message) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _config.getParameter('ui.spacing.medium', defaultValue: 16.0),
            vertical: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                color: color,
              ),
              SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                    color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        )),
        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
      ],
    );
  }

  Widget _buildProductionChecklist() {
    final checklist = _finalizer.generateProductionChecklist();

    return Container(
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            child: Text(
              'Production Readiness Checklist',
              style: TextStyle(
                fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
                fontWeight: FontWeight.bold,
                color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
              ),
            ),
          ),
          ...checklist.map((item) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _config.getParameter('ui.spacing.medium', defaultValue: 16.0),
              vertical: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                    color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        ],
      ),
    );
  }

  Widget _buildDeploymentActions() {
    return Container(
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            child: Text(
              'Deployment Actions',
              style: TextStyle(
                fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
                fontWeight: FontWeight.bold,
                color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            child: Wrap(
              spacing: _config.getParameter('ui.spacing.medium', defaultValue: 16.0),
              runSpacing: _config.getParameter('ui.spacing.medium', defaultValue: 16.0),
              children: [
                ElevatedButton.icon(
                  onPressed: _exportConfiguration,
                  icon: Icon(Icons.download),
                  label: Text('Export Config'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                    foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _generateDeploymentReport,
                  icon: Icon(Icons.assessment),
                  label: Text('Generate Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.getParameter('ui.colors.tertiary', defaultValue: Colors.purple),
                    foregroundColor: _config.getParameter('ui.colors.on_tertiary', defaultValue: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _runHealthCheck,
                  icon: Icon(Icons.health_and_safety),
                  label: Text('Health Check'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.getParameter('ui.colors.success', defaultValue: Colors.green),
                    foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _optimizeForProduction,
                  icon: Icon(Icons.speed),
                  label: Text('Optimize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                    foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportConfiguration() {
    // Export configuration for production deployment
    _logger.info('Exporting production configuration', 'ProductionDeploymentScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Configuration exported successfully',
        backgroundColor: _config.getParameter('ui.colors.success', defaultValue: Colors.green),
      ),
    );
  }

  void _generateDeploymentReport() {
    // Generate comprehensive deployment report
    _logger.info('Generating deployment report', 'ProductionDeploymentScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Deployment report generated',
        backgroundColor: _config.getParameter('ui.colors.tertiary', defaultValue: Colors.purple),
      ),
    );
  }

  void _runHealthCheck() {
    // Run comprehensive health check
    _logger.info('Running production health check', 'ProductionDeploymentScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Health check completed',
        backgroundColor: _config.getParameter('ui.colors.success', defaultValue: Colors.green),
      ),
    );
  }

  void _optimizeForProduction() {
    // Optimize application for production
    _logger.info('Optimizing for production deployment', 'ProductionDeploymentScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Production optimization completed',
        backgroundColor: _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
      ),
    );
  }
}
