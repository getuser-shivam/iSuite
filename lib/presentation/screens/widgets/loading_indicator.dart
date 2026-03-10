import 'package:flutter/material.dart';

// Infrastructure services
import '../../../core/config/central_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loading indicator widget using CentralConfig parameters
/// No hardcoded values - everything is configurable
class LoadingIndicator extends ConsumerWidget {
  final String message;
  final double? size;

  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get config from provider instead of direct access
    final config = ref.watch(centralConfigProvider);

    // Get configured values with defaults
    final indicatorSize = size ??
        config.getParameter('ui.loading_indicator.size', defaultValue: 24.0);
    final textSize =
        config.getParameter('ui.font_size_md', defaultValue: 16.0);
    final textWeight = FontWeight.values[
        config.getParameter('ui.font_weight_medium', defaultValue: 500)];
    final textColor = Theme.of(context).colorScheme.onSurface;
    final indicatorColor = Theme.of(context).colorScheme.primary;
    final spacing =
        config.getParameter('ui.spacing_md', defaultValue: 16.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            strokeWidth: configToUse.getParameter(
                'ui.progress_indicator_stroke_width',
                defaultValue: 4.0),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          message,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: textWeight,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Linear loading indicator widget using CentralConfig parameters
class LinearLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? height;
  final CentralConfig? config;

  const LinearLoadingIndicator({
    super.key,
    this.message,
    this.height,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Get config from parameter or from context
    final configToUse = config ?? CentralConfig.instance;

    // Get configured values with defaults
    final indicatorHeight = height ??
        configToUse.getParameter('ui.progress_indicator_height',
            defaultValue: 4.0);
    final textSize =
        configToUse.getParameter('ui.font_size_sm', defaultValue: 14.0);
    final textWeight = FontWeight.values[
        configToUse.getParameter('ui.font_weight_regular', defaultValue: 400)];
    final textColor = Theme.of(context).colorScheme.onSurface;
    final indicatorColor = Theme.of(context).colorScheme.primary;
    final spacing =
        configToUse.getParameter('ui.spacing_sm', defaultValue: 8.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: indicatorHeight,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
        if (message != null) ...[
          SizedBox(height: spacing),
          Text(
            message!,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: textWeight,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Skeleton loading widget using CentralConfig parameters
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final CentralConfig? config;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius,
    this.config,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Get config for animation duration
    final configToUse = widget.config ?? CentralConfig.instance;
    final animationDuration =
        configToUse.getParameter('ui.animation_normal', defaultValue: 300);

    _controller = AnimationController(
      duration: Duration(milliseconds: animationDuration),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configToUse = widget.config ?? CentralConfig.instance;
    final borderRadius = widget.borderRadius ??
        BorderRadius.circular(
            configToUse.getParameter('ui.border_radius_md', defaultValue: 8.0));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceVariant
                .withOpacity(_animation.value),
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }
}

/// Skeleton list loading widget using CentralConfig parameters
class SkeletonListLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;
  final CentralConfig? config;

  const SkeletonListLoading({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 60.0,
    this.padding,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final configToUse = config ?? CentralConfig.instance;
    final defaultPadding = padding ??
        EdgeInsets.symmetric(
          horizontal:
              configToUse.getParameter('ui.spacing_md', defaultValue: 16.0),
          vertical:
              configToUse.getParameter('ui.spacing_sm', defaultValue: 8.0),
        );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: defaultPadding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(
        height: configToUse.getParameter('ui.spacing_sm', defaultValue: 8.0),
      ),
      itemBuilder: (context, index) {
        return Row(
          children: [
            // Avatar skeleton
            SkeletonLoading(
              width: configToUse.getParameter('ui.icon_size_lg',
                  defaultValue: 32.0),
              height: configToUse.getParameter('ui.icon_size_lg',
                  defaultValue: 32.0),
              borderRadius: BorderRadius.circular(
                configToUse.getParameter('ui.border_radius_xxl',
                    defaultValue: 24.0),
              ),
              config: configToUse,
            ),
            SizedBox(
                width: configToUse.getParameter('ui.spacing_md',
                    defaultValue: 16.0)),
            // Text skeletons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoading(
                    width: double.infinity,
                    height: configToUse.getParameter('ui.font_size_md',
                        defaultValue: 16.0),
                    config: configToUse,
                  ),
                  SizedBox(
                      height: configToUse.getParameter('ui.spacing_xs',
                          defaultValue: 4.0)),
                  SkeletonLoading(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: configToUse.getParameter('ui.font_size_sm',
                        defaultValue: 14.0),
                    config: configToUse,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Configurable loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Widget? loadingWidget;
  final CentralConfig? config;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.loadingWidget,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final configToUse = config ?? CentralConfig.instance;

    if (!isLoading) {
      return child;
    }

    final overlayOpacity =
        configToUse.getParameter('ui.opacity_overlay', defaultValue: 0.8);
    final borderRadius =
        configToUse.getParameter('ui.border_radius_lg', defaultValue: 12.0);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Theme.of(context)
                .colorScheme
                .surface
                .withOpacity(overlayOpacity),
            child: Center(
              child: loadingWidget ??
                  LoadingIndicator(
                    message: loadingMessage ?? 'Loading...',
                    config: configToUse,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Refresh indicator wrapper using CentralConfig parameters
class ConfigurableRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final CentralConfig? config;

  const ConfigurableRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final configToUse = config ?? CentralConfig.instance;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      strokeWidth: configToUse.getParameter(
          'ui.progress_indicator_stroke_width',
          defaultValue: 3.0),
      displacement: configToUse.getParameter(
          'ui.refresh_indicator_displacement',
          defaultValue: 40.0),
      child: child,
    );
  }
}

/// Loading button widget using CentralConfig parameters
class LoadingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CentralConfig? config;

  const LoadingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.config,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    final configToUse = widget.config ?? CentralConfig.instance;

    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        elevation:
            configToUse.getParameter('ui.elevation_md', defaultValue: 2.0),
        backgroundColor: widget.isLoading
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.primary,
        foregroundColor: widget.isLoading
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onPrimary,
        minimumSize: Size(
          double.infinity,
          configToUse.getParameter('ui.button_height_md', defaultValue: 48.0),
        ),
        padding: EdgeInsets.symmetric(
          horizontal:
              configToUse.getParameter('ui.spacing_lg', defaultValue: 24.0),
          vertical:
              configToUse.getParameter('ui.spacing_md', defaultValue: 16.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            configToUse.getParameter('ui.border_radius_md', defaultValue: 8.0),
          ),
        ),
      ),
      child: widget.isLoading
          ? SizedBox(
              width: configToUse.getParameter('ui.icon_size_md',
                  defaultValue: 24.0),
              height: configToUse.getParameter('ui.icon_size_md',
                  defaultValue: 24.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
                strokeWidth: configToUse.getParameter(
                    'ui.progress_indicator_stroke_width',
                    defaultValue: 2.0),
              ),
            )
          : widget.child,
    );
  }
}

/// Empty state widget using CentralConfig parameters
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final CentralConfig? config;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final configToUse = config ?? CentralConfig.instance;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
            configToUse.getParameter('ui.spacing_lg', defaultValue: 24.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: configToUse.getParameter('ui.icon_size_xl',
                  defaultValue: 48.0),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(
                height: configToUse.getParameter('ui.spacing_md',
                    defaultValue: 16.0)),
            Text(
              title,
              style: TextStyle(
                fontSize: configToUse.getParameter('ui.font_size_xl',
                    defaultValue: 20.0),
                fontWeight: FontWeight.values[configToUse
                    .getParameter('ui.font_weight_medium', defaultValue: 500)],
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(
                  height: configToUse.getParameter('ui.spacing_sm',
                      defaultValue: 8.0)),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: configToUse.getParameter('ui.font_size_md',
                      defaultValue: 16.0),
                  fontWeight: FontWeight.values[configToUse.getParameter(
                      'ui.font_weight_regular',
                      defaultValue: 400)],
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(
                  height: configToUse.getParameter('ui.spacing_lg',
                      defaultValue: 24.0)),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget using CentralConfig parameters
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final CentralConfig? config;

  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final configToUse = config ?? CentralConfig.instance;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
            configToUse.getParameter('ui.spacing_lg', defaultValue: 24.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: configToUse.getParameter('ui.icon_size_xl',
                  defaultValue: 48.0),
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(
                height: configToUse.getParameter('ui.spacing_md',
                    defaultValue: 16.0)),
            Text(
              title,
              style: TextStyle(
                fontSize: configToUse.getParameter('ui.font_size_xl',
                    defaultValue: 20.0),
                fontWeight: FontWeight.values[configToUse
                    .getParameter('ui.font_weight_medium', defaultValue: 500)],
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(
                  height: configToUse.getParameter('ui.spacing_sm',
                      defaultValue: 8.0)),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: configToUse.getParameter('ui.font_size_md',
                      defaultValue: 16.0),
                  fontWeight: FontWeight.values[configToUse.getParameter(
                      'ui.font_weight_regular',
                      defaultValue: 400)],
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(
                  height: configToUse.getParameter('ui.spacing_lg',
                      defaultValue: 24.0)),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
