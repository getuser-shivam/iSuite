import 'package:flutter/material.dart';
import '../../core/config/central_config.dart';

class FeatureCard extends StatefulWidget {
  const FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
    this.color,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  final CentralConfig _config = CentralConfig.instance;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.fast', defaultValue: 200)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: _config.getParameter('ui.animation.scale.begin', defaultValue: 1.0),
      end: _config.getParameter('ui.animation.scale.end', defaultValue: 0.95),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: _config.getParameter('ui.animation.opacity.begin', defaultValue: 1.0),
      end: _config.getParameter('ui.animation.opacity.end', defaultValue: 0.7),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? _config.primaryColor;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Card(
              elevation: _config.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
              shadowColor: cardColor.withOpacity(_config.getParameter('ui.shadow.opacity', defaultValue: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.large', defaultValue: 16.0)),
                side: BorderSide(
                  color: cardColor.withOpacity(_config.getParameter('ui.border.opacity', defaultValue: 0.1)),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.large', defaultValue: 16.0)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor.withOpacity(_config.getParameter('ui.gradient.opacity.start', defaultValue: 0.05)),
                      cardColor.withOpacity(_config.getParameter('ui.gradient.opacity.end', defaultValue: 0.1)),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(_config.getParameter('ui.icon.background.opacity', defaultValue: 0.1)),
                          borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
                        ),
                        child: Icon(
                          widget.icon,
                          size: _config.getParameter('ui.icon.size.large', defaultValue: 32.0),
                          color: cardColor,
                        ),
                      ),
                      SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 16.0),
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                          fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                          color: _config.primaryColor.withOpacity(_config.getParameter('ui.opacity.secondary_text', defaultValue: 0.6)),
                          fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: _config.getParameter('ui.text.max_lines', defaultValue: 2),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.isLoading) ...[
                        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                        SizedBox(
                          width: _config.getParameter('ui.loading.size.small', defaultValue: 20.0),
                          height: _config.getParameter('ui.loading.size.small', defaultValue: 20.0),
                          child: CircularProgressIndicator(
                            strokeWidth: _config.getParameter('ui.loading.stroke_width', defaultValue: 2.0),
                            valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
