import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/ui/ui_config_service.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';

/// Enhanced UI Components Library
/// Provides reusable UI components with proper central configuration
class EnhancedUIComponents {
  static final UIConfigService _config = UIConfigService();
  static final LoggingService _logger = LoggingService();

  /// Enhanced App Bar with configuration
  static AppBar buildAppBar({
    String? title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: title != null ? Text(
        title,
        style: TextStyle(
          fontSize: _config.getDouble('ui.font_size') + 2,
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? _config.getColor('ui.on_primary'),
        ),
      ) : null,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? _config.getColor('ui.primary_color'),
      foregroundColor: foregroundColor ?? _config.getColor('ui.on_primary'),
      elevation: elevation ?? _config.getDouble('ui.elevation'),
      bottom: bottom,
      toolbarHeight: _config.getDouble('ui.app_bar_height'),
    );
  }

  /// Enhanced Card with configuration
  static Widget buildCard({
    required Widget child,
    Color? color,
    Color? shadowColor,
    double? elevation,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    EdgeInsetsGeometry? margin,
    Clip clipBehavior = Clip.antiAlias,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      color: color ?? _config.getColor('ui.surface_color'),
      shadowColor: shadowColor,
      elevation: elevation ?? _config.getDouble('ui.card_elevation'),
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
      ),
      borderOnForeground: borderOnForeground,
      margin: margin ?? EdgeInsets.all(_config.getDouble('ui.margin')),
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? EdgeInsets.all(_config.getDouble('ui.padding')),
        child: child,
      ),
    );
  }

  /// Enhanced Elevated Button with configuration
  static Widget buildElevatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? shadowColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    double? width,
    double? height,
    OutlinedBorder? shape,
    bool enabled = true,
    ButtonStyle? style,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: style ?? ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? _config.getColor('ui.primary_color'),
        foregroundColor: foregroundColor ?? _config.getColor('ui.on_primary'),
        shadowColor: shadowColor,
        elevation: elevation ?? _config.getDouble('ui.elevation'),
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: _config.getDouble('ui.padding'),
          vertical: _config.getDouble('ui.padding') / 2,
        ),
        minimumSize: minimumSize ?? Size(0, _config.getDouble('ui.button_height')),
        fixedSize: fixedSize ?? (width != null || height != null ? Size(width ?? 0, height ?? 0) : null),
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
        ),
      ),
      child: child,
    );
  }

  /// Enhanced Text Button with configuration
  static Widget buildTextButton({
    required Widget child,
    required VoidCallback onPressed,
    Color? foregroundColor,
    Color? overlayColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    double? width,
    double? height,
    OutlinedBorder? shape,
    bool enabled = true,
    ButtonStyle? style,
  }) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: style ?? TextButton.styleFrom(
        foregroundColor: foregroundColor ?? _config.getColor('ui.primary_color'),
        overlayColor: overlayColor,
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: _config.getDouble('ui.padding'),
          vertical: _config.getDouble('ui.padding') / 2,
        ),
        minimumSize: minimumSize ?? Size(0, _config.getDouble('ui.button_height')),
        fixedSize: fixedSize ?? (width != null || height != null ? Size(width ?? 0, height ?? 0) : null),
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
        ),
      ),
      child: child,
    );
  }

  /// Enhanced Outlined Button with configuration
  static Widget buildOutlinedButton({
    required Widget child,
    required VoidCallback onPressed,
    Color? foregroundColor,
    Color? backgroundColor,
    Color? overlayColor,
    Color? sideColor,
    double? sideWidth,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    double? width,
    double? height,
    OutlinedBorder? shape,
    bool enabled = true,
    ButtonStyle? style,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: style ?? OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? _config.getColor('ui.primary_color'),
        backgroundColor: backgroundColor,
        overlayColor: overlayColor,
        side: BorderSide(
          color: sideColor ?? _config.getColor('ui.primary_color'),
          width: sideWidth ?? 1.0,
        ),
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: _config.getDouble('ui.padding'),
          vertical: _config.getDouble('ui.padding') / 2,
        ),
        minimumSize: minimumSize ?? Size(0, _config.getDouble('ui.button_height')),
        fixedSize: fixedSize ?? (width != null || height != null ? Size(width ?? 0, height ?? 0) : null),
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
        ),
      ),
      child: child,
    );
  }

  /// Enhanced Icon Button with configuration
  static Widget buildIconButton({
    required Widget icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? splashColor,
    double? iconSize,
    EdgeInsetsGeometry? padding,
    BoxConstraints? constraints,
    bool enabled = true,
    ButtonStyle? style,
  }) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: icon,
      iconSize: iconSize ?? _config.getDouble('ui.icon_size'),
      style: style ?? IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor ?? _config.getColor('ui.on_surface'),
        splashColor: splashColor,
        padding: padding ?? EdgeInsets.all(_config.getDouble('ui.padding') / 2),
        constraints: constraints,
      ),
    );
  }

  /// Enhanced Floating Action Button with configuration
  static Widget buildFloatingActionButton({
    required Widget child,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? splashColor,
    double? elevation,
    ShapeBorder? shape,
    bool extended = false,
    Widget? label,
    Clip clipBehavior = Clip.antiAlias,
    FocusNode? focusNode,
    bool autofocus = false,
    MaterialTapTargetSize? materialTapTargetSize,
    bool enableFeedback = true,
    Widget? heroTag,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? _config.getColor('ui.accent_color'),
      foregroundColor: foregroundColor ?? _config.getColor('ui.on_accent'),
      splashColor: splashColor,
      elevation: elevation ?? _config.getDouble('ui.elevation'),
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
      ),
      extended: extended,
      child: extended ? label : child,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
      materialTapTargetSize: materialTapTargetSize,
      enableFeedback: enableFeedback,
      heroTag: heroTag,
    );
  }

  /// Enhanced Text Field with configuration
  static Widget buildTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    String? helperText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    bool enableSuggestions = true,
    bool autocorrect = true,
    bool enabled = true,
    bool readOnly = false,
    bool autofocus = false,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    VoidCallback? onEditingComplete,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
    Widget? suffix,
    EdgeInsetsGeometry? contentPadding,
    InputBorder? border,
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    InputBorder? errorBorder,
    Color? fillColor,
    bool filled = false,
    TextStyle? style,
    TextAlign? textAlign,
    TextAlignVertical? textAlignVertical,
    String? initialValue,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: contentPadding ?? EdgeInsets.symmetric(
          horizontal: _config.getDouble('ui.padding'),
          vertical: _config.getDouble('ui.padding') / 2,
        ),
        border: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
        ),
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
          borderSide: BorderSide(color: _config.getColor('ui.primary_color')),
        ),
        errorBorder: errorBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
          borderSide: BorderSide(color: _config.getColor('ui.error_color')),
        ),
        filled: filled,
        fillColor: fillColor,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      inputFormatters: inputFormatters,
      style: style ?? TextStyle(
        fontSize: _config.getDouble('ui.font_size'),
        color: _config.getColor('ui.on_surface'),
      ),
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      initialValue: initialValue,
      focusNode: focusNode,
    );
  }

  /// Enhanced Chip with configuration
  static Widget buildChip({
    required Widget label,
    Widget? avatar,
    Widget? deleteIcon,
    VoidCallback? onDeleted,
    Color? backgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    bool autofocus = false,
    Color? selectedColor,
    Color? checkmarkColor,
    bool selected = false,
    bool showCheckmark = true,
    Widget? deleteIconTooltip,
    MaterialTapTargetSize? materialTapTargetSize,
    bool enableFeedback = true,
    BorderSide? side,
    OutlinedBorder? avatarBorder,
    IconThemeData? avatarTheme,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? labelPadding,
    bool pressElevation = true,
    double? tapElevation,
    MouseCursor? mouseCursor,
    FocusNode? focusNode,
    bool disabled = false,
  }) {
    return Chip(
      label: label,
      avatar: avatar,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      backgroundColor: backgroundColor ?? _config.getColor('ui.surface_color'),
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: _config.getDouble('ui.padding') / 2,
        vertical: _config.getDouble('ui.padding') / 4,
      ),
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
      ),
      clipBehavior: clipBehavior,
      autofocus: autofocus,
      selectedColor: selectedColor ?? _config.getColor('ui.primary_color'),
      checkmarkColor: checkmarkColor,
      selected: selected,
      showCheckmark: showCheckmark,
      deleteIconTooltip: deleteIconTooltip,
      materialTapTargetSize: materialTapTargetSize,
      enableFeedback: enableFeedback,
      side: side,
      avatarBorder: avatarBorder,
      avatarTheme: avatarTheme,
      labelStyle: labelStyle ?? TextStyle(
        fontSize: _config.getDouble('ui.font_size') - 2,
        color: _config.getColor('ui.on_surface'),
      ),
      labelPadding: labelPadding,
      pressElevation: pressElevation,
      tapElevation: tapElevation,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      disabled: disabled,
    );
  }

  /// Enhanced Progress Indicator with configuration
  static Widget buildLinearProgressIndicator({
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation<Color?>? valueColor,
    minHeight,
    semanticsLabel,
    semanticsValue,
  }) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: backgroundColor ?? _config.getColor('ui.surface_color'),
      color: color ?? _config.getColor('ui.primary_color'),
      valueColor: valueColor,
      minHeight: minHeight ?? _config.getDouble('ui.progress_bar_height'),
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
    );
  }

  /// Enhanced Circular Progress Indicator with configuration
  static Widget buildCircularProgressIndicator({
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation<Color?>? valueColor,
    double? strokeWidth,
    semanticsLabel,
    semanticsValue,
  }) {
    return CircularProgressIndicator(
      value: value,
      backgroundColor: backgroundColor,
      color: color ?? _config.getColor('ui.primary_color'),
      valueColor: valueColor,
      strokeWidth: strokeWidth,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
    );
  }

  /// Enhanced Divider with configuration
  static Widget buildDivider({
    Color? color,
    double? height,
    double? thickness,
    double? indent,
    double? endIndent,
  }) {
    return Divider(
      color: color ?? _config.getColor('ui.divider_color'),
      height: height ?? _config.getDouble('ui.divider_height'),
      thickness: thickness ?? 1.0,
      indent: indent,
      endIndent: endIndent,
    );
  }

  /// Enhanced Icon with configuration
  static Widget buildIcon({
    required IconData icon,
    double? size,
    Color? color,
    String? semanticLabel,
    TextDirection? textDirection,
  }) {
    return Icon(
      icon,
      size: size ?? _config.getDouble('ui.icon_size'),
      color: color ?? _config.getColor('ui.on_surface'),
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }

  /// Enhanced Text with configuration
  static Widget buildText({
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    String? semanticsLabel,
    TextDirection? textDirection,
    bool? softWrap,
    double? textScaleFactor,
    int? maxCharacters,
  }) {
    return Text(
      text,
      style: style ?? TextStyle(
        fontSize: _config.getDouble('ui.font_size'),
        color: _config.getColor('ui.on_surface'),
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textDirection: textDirection,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
      maxCharacters: maxCharacters,
    );
  }

  /// Enhanced List Tile with configuration
  static Widget buildListTile({
    Widget? leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    bool isThreeLine = false,
    bool? dense,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    Color? iconColor,
    Color? textColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? leadingAndTrailingTextStyle,
    ShapeBorder? shape,
    bool selected = false,
    bool focusColor,
    bool hoverColor,
    Color? splashColor,
    Color? focusColor,
    Color? hoverColor,
    bool autofocus = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    MouseCursor? mouseCursor,
    bool enabled = true,
    FocusNode? focusNode,
    bool enableFeedback = true,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      contentPadding: contentPadding ?? EdgeInsets.symmetric(
        horizontal: _config.getDouble('ui.padding'),
        vertical: _config.getDouble('ui.padding') / 4,
      ),
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      iconColor: iconColor ?? _config.getColor('ui.on_surface'),
      textColor: textColor ?? _config.getColor('ui.on_surface'),
      titleTextStyle: titleTextStyle ?? TextStyle(
        fontSize: _config.getDouble('ui.font_size'),
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: subtitleTextStyle ?? TextStyle(
        fontSize: _config.getDouble('ui.font_size') - 2,
        color: _config.getColor('ui.on_surface').withOpacity(0.7),
      ),
      leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
      shape: shape,
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      mouseCursor: mouseCursor,
      enabled: enabled,
      focusNode: focusNode,
      enableFeedback: enableFeedback,
    );
  }

  /// Enhanced Switch with configuration
  static Widget buildSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
    Color? activeTrackColor,
    Color? inactiveThumbColor,
    Color? inactiveTrackColor,
    MaterialTapTargetSize? materialTapTargetSize,
    MouseCursor? mouseCursor,
    FocusNode? focusNode,
    bool autofocus = false,
    bool enableFeedback = true,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? _config.getColor('ui.accent_color'),
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
      materialTapTargetSize: materialTapTargetSize,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
    );
  }

  /// Enhanced Checkbox with configuration
  static Widget buildCheckbox({
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
    Color? checkColor,
    Color? focusColor,
    Color? hoverColor,
    MaterialTapTargetSize? materialTapTargetSize,
    MouseCursor? mouseCursor,
    bool? tristate,
    OutlinedBorder? shape,
    BorderSide? side,
    FocusNode? focusNode,
    bool autofocus = false,
    bool enableFeedback = true,
  }) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? _config.getColor('ui.accent_color'),
      checkColor: checkColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      materialTapTargetSize: materialTapTargetSize,
      mouseCursor: mouseCursor,
      tristate: tristate,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: side,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
    );
  }

  /// Enhanced Radio with configuration
  static Widget buildRadio<T>({
    required T value,
    required T groupValue,
    required ValueChanged<T>? onChanged,
    Color? activeColor,
    Color? focusColor,
    Color? hoverColor,
    MaterialTapTargetSize? materialTapTargetSize,
    MouseCursor? mouseCursor,
    FocusNode? focusNode,
    bool autofocus = false,
    bool enableFeedback = true,
  }) {
    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor ?? _config.getColor('ui.accent_color'),
      focusColor: focusColor,
      hoverColor: hoverColor,
      materialTapTargetSize: materialTapTargetSize,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
    );
  }

  /// Enhanced Slider with configuration
  static Widget buildSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double? min,
    double? max,
    int? divisions,
    String? label,
    Color? activeColor,
    Color? inactiveColor,
    Color? thumbColor,
    Color? overlayColor,
    MouseCursor? mouseCursor,
    bool? semanticFormatterCallback,
    FocusNode? focusNode,
    bool autofocus = false,
    bool enableFeedback = true,
  }) {
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min ?? 0.0,
      max: max ?? 1.0,
      divisions: divisions,
      label: label,
      activeColor: activeColor ?? _config.getColor('ui.accent_color'),
      inactiveColor: inactiveColor,
      thumbColor: thumbColor,
      overlayColor: overlayColor,
      mouseCursor: mouseCursor,
      semanticFormatterCallback: semanticFormatterCallback,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
    );
  }

  /// Enhanced Dialog with configuration
  static Widget buildDialog({
    required Widget child,
    String? title,
    Widget? content,
    List<Widget>? actions,
    EdgeInsetsGeometry? titlePadding,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? actionsPadding,
    Color? backgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    ShapeBorder? shape,
    Clip clipBehavior,
    InsetAnimationDuration? insetAnimationDuration,
    InsetAnimationCurve? insetAnimationCurve,
    Alignment? alignment,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    return AlertDialog(
      title: title != null ? Text(
        title,
        style: TextStyle(
          fontSize: _config.getDouble('ui.font_size') + 2,
          fontWeight: FontWeight.bold,
        ),
      ) : null,
      content: content,
      actions: actions,
      titlePadding: titlePadding,
      contentPadding: contentPadding ?? EdgeInsets.all(_config.getDouble('ui.padding')),
      actionsPadding: actionsPadding ?? EdgeInsets.all(_config.getDouble('ui.padding')),
      backgroundColor: backgroundColor ?? _config.getColor('ui.surface_color'),
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation ?? _config.getDouble('ui.elevation'),
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.getDouble('ui.border_radius')),
      ),
      clipBehavior: clipBehavior,
      insetAnimationDuration: insetAnimationDuration,
      insetAnimationCurve: insetAnimationCurve,
      alignment: alignment,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Enhanced Bottom Sheet with configuration
  static Widget buildBottomSheet({
    required Widget child,
    Color? backgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    ShapeBorder? shape,
    Clip clipBehavior,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enableDrag = true,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool? showDragHandle,
    bool? useSafeArea,
    RouteSettings? routeSettings,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(_config.getDouble('ui.padding')),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? _config.getColor('ui.surface_color'),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_config.getDouble('ui.border_radius')),
        ),
      ),
      child: child,
    );
  }

  /// Enhanced Tab Bar with configuration
  static Widget buildTabBar({
    required List<Widget> tabs,
    TabController? controller,
    bool isScrollable = false,
    Color? indicatorColor,
    Color? labelColor,
    Color? unselectedLabelColor,
    Color? labelStyle,
    Color? unselectedLabelStyle,
    Color? overlayColor,
    MouseCursor? mouseCursor,
    EdgeInsetsGeometry? padding,
    Color? splashFactory,
    bool enableFeedback = true,
    DragStartBehavior? dragStartBehavior,
    bool? onTap,
    ScrollPhysics? physics,
    TabAlignment? tabAlignment,
    TextDirection? textDirection,
    bool? automaticIndicatorColorAdjustment,
    EdgeInsetsGeometry? indicatorPadding,
    double? indicatorWeight,
    double? indicatorSize,
    BorderSide? dividerColor,
    double? dividerHeight,
    TabBarIndicatorSize? indicatorSize,
  }) {
    return TabBar(
      tabs: tabs,
      controller: controller,
      isScrollable: isScrollable,
      indicatorColor: indicatorColor ?? _config.getColor('ui.accent_color'),
      labelColor: labelColor ?? _config.getColor('ui.on_surface'),
      unselectedLabelColor: unselectedLabelColor ?? _config.getColor('ui.on_surface').withOpacity(0.6),
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      overlayColor: overlayColor,
      mouseCursor: mouseCursor,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: _config.getDouble('ui.padding'),
        vertical: _config.getDouble('ui.padding') / 4,
      ),
      splashFactory: splashFactory,
      enableFeedback: enableFeedback,
      dragStartBehavior: dragStartBehavior,
      onTap: onTap,
      physics: physics,
      tabAlignment: tabAlignment,
      textDirection: textDirection,
      automaticIndicatorColorAdjustment: automaticIndicatorColorAdjustment,
      indicatorPadding: indicatorPadding,
      indicatorWeight: indicatorWeight,
      indicatorSize: indicatorSize,
      dividerColor: dividerColor,
      dividerHeight: dividerHeight,
    );
  }
}

/// Extension methods for easy access to enhanced UI components
extension EnhancedUIComponentsExtension on Widget {
  /// Wrap with enhanced card
  Widget withEnhancedCard({
    Color? color,
    Color? shadowColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return EnhancedUIComponents.buildCard(
      color: color,
      shadowColor: shadowColor,
      elevation: elevation,
      margin: margin,
      padding: padding,
      child: this,
    );
  }

  /// Wrap with enhanced padding
  Widget withEnhancedPadding({
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    double padding = 0;
    if (all != null) {
      padding = all!;
    } else {
      if (horizontal != null) padding += horizontal!;
      if (vertical != null) padding += vertical!;
    }
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: this,
    );
  }

  /// Wrap with enhanced margin
  Widget withEnhancedMargin({
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    double margin = 0;
    if (all != null) {
      margin = all!;
    } else {
      if (horizontal != null) margin += horizontal!;
      if (vertical != null) margin += vertical!;
    }
    
    return Container(
      margin: EdgeInsets.all(margin),
      child: this,
    );
  }
}
