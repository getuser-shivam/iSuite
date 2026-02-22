import 'package:flutter/material.dart';
import '../../core/config/central_config.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: config.getParameter('ui.font.size.title_large', defaultValue: 22.0),
            fontWeight: FontWeight.bold,
            fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
          ),
        ),
        SizedBox(height: config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        SizedBox(
          height: config.getParameter('ui.quick_actions.height', defaultValue: 80.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickActionButton(
                icon: Icons.add_task,
                label: 'New Task',
                color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Add task feature coming soon!'),
                      duration: Duration(milliseconds: config.getParameter('ui.notification.duration.short', defaultValue: 2000)),
                    ),
                  );
                },
              ),
              _QuickActionButton(
                icon: Icons.note_add,
                label: 'New Note',
                color: config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Add note feature coming soon!'),
                      duration: Duration(milliseconds: config.getParameter('ui.notification.duration.short', defaultValue: 2000)),
                    ),
                  );
                },
              ),
              _QuickActionButton(
                icon: Icons.event,
                label: 'New Event',
                color: config.getParameter('ui.colors.secondary', defaultValue: Colors.green),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Add event feature coming soon!'),
                      duration: Duration(milliseconds: config.getParameter('ui.notification.duration.short', defaultValue: 2000)),
                    ),
                  );
                },
              ),
              _QuickActionButton(
                icon: Icons.upload_file,
                label: 'Upload',
                color: config.getParameter('ui.colors.accent', defaultValue: Colors.purple),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Upload feature coming soon!'),
                      duration: Duration(milliseconds: config.getParameter('ui.notification.duration.short', defaultValue: 2000)),
                    ),
                  );
                },
              ),
              _QuickActionButton(
                icon: Icons.share,
                label: 'Share',
                color: config.getParameter('ui.colors.error', defaultValue: Colors.red),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share feature coming soon!'),
                      duration: Duration(milliseconds: config.getParameter('ui.notification.duration.short', defaultValue: 2000)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  final CentralConfig _config = CentralConfig.instance;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.fast', defaultValue: 150)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: _config.getParameter('ui.animation.scale.begin', defaultValue: 1.0),
      end: _config.getParameter('ui.animation.scale.end', defaultValue: 0.9),
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
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: _config.getParameter('ui.quick_actions.button_width', defaultValue: 80.0),
              margin: EdgeInsets.only(right: _config.getParameter('ui.quick_actions.button_margin', defaultValue: 12.0)),
              child: Column(
                children: [
                  Container(
                    width: _config.getParameter('ui.quick_actions.icon_container_size', defaultValue: 56.0),
                    height: _config.getParameter('ui.quick_actions.icon_container_size', defaultValue: 56.0),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(_config.getParameter('ui.icon.background.opacity', defaultValue: 0.1)),
                      borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.large', defaultValue: 16.0)),
                      border: Border.all(
                        color: widget.color.withOpacity(_config.getParameter('ui.border.opacity', defaultValue: 0.2)),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: _config.getParameter('ui.icon.size.large', defaultValue: 28.0),
                    ),
                  ),
                  SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                      fontWeight: FontWeight.w500,
                      color: widget.color,
                      fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: _config.getParameter('ui.text.max_lines', defaultValue: 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
