import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? customIcon;
  final VoidCallback? onAction;
  final String? actionText;
  final Widget? customAction;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.customIcon,
    this.onAction,
    this.actionText,
    this.customAction,
    this.padding,
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(context),
          const SizedBox(height: 24),
          _buildTitle(context),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            _buildSubtitle(context),
          ],
          if (onAction != null || customAction != null) ...[
            const SizedBox(height: 24),
            _buildAction(context),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (customIcon != null) {
      return customIcon!;
    }
    
    return Icon(
      icon ?? Mdi.inboxOutline,
      size: iconSize ?? 64,
      color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: titleStyle ?? Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      subtitle!,
      textAlign: TextAlign.center,
      style: subtitleStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (customAction != null) {
      return customAction!;
    }
    
    return ElevatedButton.icon(
      onPressed: onAction,
      icon: const Icon(Icons.add),
      label: Text(actionText ?? 'Add Item'),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;
  final Widget? customAction;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;

  const EmptyStateCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionText,
    this.customAction,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      shape: shape,
      color: backgroundColor,
      child: EmptyStateWidget(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onAction: onAction,
        actionText: actionText,
        customAction: customAction,
        padding: padding ?? const EdgeInsets.all(24),
      ),
    );
  }
}

class EmptyStateSliver extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;
  final Widget? customAction;
  final EdgeInsetsGeometry? padding;

  const EmptyStateSliver({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionText,
    this.customAction,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyStateWidget(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onAction: onAction,
        actionText: actionText,
        customAction: customAction,
        padding: padding ?? const EdgeInsets.all(32),
      ),
    );
  }
}

// Predefined empty states
class TaskEmptyState extends StatelessWidget {
  final VoidCallback? onAddTask;

  const TaskEmptyState({Key? key, this.onAddTask}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No tasks yet',
      subtitle: 'Create your first task to get started with organizing your work',
      icon: Mdi.clipboardTextOutline,
      onAction: onAddTask,
      actionText: 'Create Task',
    );
  }
}

class NoteEmptyState extends StatelessWidget {
  final VoidCallback? onAddNote;

  const NoteEmptyState({Key? key, this.onAddNote}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No notes yet',
      subtitle: 'Start writing notes to capture your thoughts and ideas',
      icon: Mdi.noteOutline,
      onAction: onAddNote,
      actionText: 'Create Note',
    );
  }
}

class FileEmptyState extends StatelessWidget {
  final VoidCallback? onUploadFile;

  const FileEmptyState({Key? key, this.onUploadFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No files yet',
      subtitle: 'Upload your first file to start managing your documents',
      icon: Mdi.folderOutline,
      onAction: onUploadFile,
      actionText: 'Upload File',
    );
  }
}

class CalendarEmptyState extends StatelessWidget {
  final VoidCallback? onAddEvent;

  const CalendarEmptyState({Key? key, this.onAddEvent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No events scheduled',
      subtitle: 'Add events to your calendar to stay organized',
      icon: Mdi.calendarOutline,
      onAction: onAddEvent,
      actionText: 'Add Event',
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  final String? query;
  final VoidCallback? onClearSearch;

  const SearchEmptyState({
    Key? key,
    this.query,
    this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: query != null ? 'No results found' : 'Search anything',
      subtitle: query != null
          ? 'Try searching with different keywords'
          : 'Find tasks, notes, files, and more',
      icon: Mdi.magnify,
      onAction: onClearSearch,
      actionText: 'Clear Search',
    );
  }
}

class NetworkEmptyState extends StatelessWidget {
  final VoidCallback? onScanNetworks;

  const NetworkEmptyState({Key? key, this.onScanNetworks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No networks found',
      subtitle: 'Scan for available WiFi networks to connect',
      icon: Mdi.wifiOutline,
      onAction: onScanNetworks,
      actionText: 'Scan Networks',
    );
  }
}

class FileSharingEmptyState extends StatelessWidget {
  final VoidCallback? onAddConnection;

  const FileSharingEmptyState({Key? key, this.onAddConnection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No connections yet',
      subtitle: 'Add a file sharing connection to start transferring files',
      icon: Mdi.shareVariantOutline,
      onAction: onAddConnection,
      actionText: 'Add Connection',
    );
  }
}

class ReminderEmptyState extends StatelessWidget {
  final VoidCallback? onAddReminder;

  const ReminderEmptyState({Key? key, this.onAddReminder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No reminders set',
      subtitle: 'Create reminders to never miss important dates and tasks',
      icon: Mdi.bellOutline,
      onAction: onAddReminder,
      actionText: 'Create Reminder',
    );
  }
}

class BackupEmptyState extends StatelessWidget {
  final VoidCallback? onCreateBackup;

  const BackupEmptyState({Key? key, this.onCreateBackup}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No backups yet',
      subtitle: 'Create your first backup to protect your data',
      icon: Mdi.backupRestore,
      onAction: onCreateBackup,
      actionText: 'Create Backup',
    );
  }
}

class AnalyticsEmptyState extends StatelessWidget {
  final VoidCallback? onEnableAnalytics;

  const AnalyticsEmptyState({Key? key, this.onEnableAnalytics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No data to analyze',
      subtitle: 'Start using the app to generate analytics insights',
      icon: Mdi.chartLine,
      onAction: onEnableAnalytics,
      actionText: 'Start Using App',
    );
  }
}

class ErrorEmptyState extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const ErrorEmptyState({
    Key? key,
    this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Something went wrong',
      subtitle: error ?? 'An unexpected error occurred',
      icon: Mdi.alertCircleOutline,
      iconColor: Theme.of(context).colorScheme.error,
      onAction: onRetry,
      actionText: 'Try Again',
    );
  }
}

class OfflineEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineEmptyState({Key? key, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No internet connection',
      subtitle: 'Check your connection and try again',
      icon: Mdi.wifiOff,
      iconColor: Theme.of(context).colorScheme.error,
      onAction: onRetry,
      actionText: 'Retry',
    );
  }
}
