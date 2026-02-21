import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ThemePreset {
  defaultLight,
  defaultDark,
  blue,
  green,
  purple,
  orange,
  custom,
}

class ThemeModel extends Equatable {
  const ThemeModel({
    required this.id,
    required this.name,
    this.preset = ThemePreset.defaultLight,
    this.mode = ThemeMode.system,
    this.primaryColor = const Color(0xFF1976D2),
    this.secondaryColor = const Color(0xFFDC143C),
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.onPrimaryColor = const Color(0xFFFFFFFF),
    this.onSecondaryColor = const Color(0xFFFFFFFF),
    this.onBackgroundColor = const Color(0xFF000000),
    this.onSurfaceColor = const Color(0xFF000000),
    this.errorColor = const Color(0xFFD32F2F),
    this.onErrorColor = const Color(0xFFFFFFFF),
    this.isCustom = false,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) => ThemeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        preset: ThemePreset.values.firstWhere((p) => p.name == json['preset']),
        mode: ThemeMode.values.firstWhere((m) => m.name == json['mode']),
        primaryColor: Color(json['primaryColor'] as int),
        secondaryColor: Color(json['secondaryColor'] as int),
        backgroundColor: Color(json['backgroundColor'] as int),
        surfaceColor: Color(json['surfaceColor'] as int),
        onPrimaryColor: Color(json['onPrimaryColor'] as int),
        onSecondaryColor: Color(json['onSecondaryColor'] as int),
        onBackgroundColor: Color(json['onBackgroundColor'] as int),
        onSurfaceColor: Color(json['onSurfaceColor'] as int),
        errorColor: Color(json['errorColor'] as int),
        onErrorColor: Color(json['onErrorColor'] as int),
        isCustom: json['isCustom'] as bool? ?? false,
      );

  // Preset themes
  factory ThemeModel.defaultLight() => const ThemeModel(
        id: 'default_light',
        name: 'Default Light',
        mode: ThemeMode.light,
      );

  factory ThemeModel.defaultDark() => const ThemeModel(
        id: 'default_dark',
        name: 'Default Dark',
        preset: ThemePreset.defaultDark,
        mode: ThemeMode.dark,
        primaryColor: Color(0xFF90CAF9),
        secondaryColor: Color(0xFFF48FB1),
        backgroundColor: Color(0xFF121212),
        surfaceColor: Color(0xFF1E1E1E),
        onPrimaryColor: Color(0xFF000000),
        onSecondaryColor: Color(0xFF000000),
        onBackgroundColor: Color(0xFFFFFFFF),
        onSurfaceColor: Color(0xFFFFFFFF),
        errorColor: Color(0xFFCF6679),
        onErrorColor: Color(0xFF000000),
      );

  factory ThemeModel.blueTheme() => const ThemeModel(
        id: 'blue_theme',
        name: 'Blue Theme',
        preset: ThemePreset.blue,
        primaryColor: Color(0xFF2196F3),
        secondaryColor: Color(0xFF00BCD4),
        backgroundColor: Color(0xFFE3F2FD),
        onSecondaryColor: Color(0xFF000000),
      );
  final String id;
  final String name;
  final ThemePreset preset;
  final ThemeMode mode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color onPrimaryColor;
  final Color onSecondaryColor;
  final Color onBackgroundColor;
  final Color onSurfaceColor;
  final Color errorColor;
  final Color onErrorColor;
  final bool isCustom;

  ThemeModel copyWith({
    String? id,
    String? name,
    ThemePreset? preset,
    ThemeMode? mode,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? onPrimaryColor,
    Color? onSecondaryColor,
    Color? onBackgroundColor,
    Color? onSurfaceColor,
    Color? errorColor,
    Color? onErrorColor,
    bool? isCustom,
  }) =>
      ThemeModel(
        id: id ?? this.id,
        name: name ?? this.name,
        preset: preset ?? this.preset,
        mode: mode ?? this.mode,
        primaryColor: primaryColor ?? this.primaryColor,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        surfaceColor: surfaceColor ?? this.surfaceColor,
        onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
        onSecondaryColor: onSecondaryColor ?? this.onSecondaryColor,
        onBackgroundColor: onBackgroundColor ?? this.onBackgroundColor,
        onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
        errorColor: errorColor ?? this.errorColor,
        onErrorColor: onErrorColor ?? this.onErrorColor,
        isCustom: isCustom ?? this.isCustom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'preset': preset.name,
        'mode': mode.name,
        'primaryColor': primaryColor.value,
        'secondaryColor': secondaryColor.value,
        'backgroundColor': backgroundColor.value,
        'surfaceColor': surfaceColor.value,
        'onPrimaryColor': onPrimaryColor.value,
        'onSecondaryColor': onSecondaryColor.value,
        'onBackgroundColor': onBackgroundColor.value,
        'onSurfaceColor': onSurfaceColor.value,
        'errorColor': errorColor.value,
        'onErrorColor': onErrorColor.value,
        'isCustom': isCustom,
      };

  // Convert to ThemeData
  ThemeData toThemeData() => ThemeData(
        useMaterial3: true,
        brightness: mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme(
          brightness:
              mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          primary: primaryColor,
          onPrimary: onPrimaryColor,
          secondary: secondaryColor,
          onSecondary: onSecondaryColor,
          error: errorColor,
          onError: onErrorColor,
          surface: surfaceColor,
          onSurface: onSurfaceColor,
        ),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        preset,
        mode,
        primaryColor,
        secondaryColor,
        backgroundColor,
        surfaceColor,
        onPrimaryColor,
        onSecondaryColor,
        onBackgroundColor,
        onSurfaceColor,
        errorColor,
        onErrorColor,
        isCustom,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeModel &&
        other.id == id &&
        other.name == name &&
        other.preset == preset &&
        other.mode == mode &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.backgroundColor == backgroundColor &&
        other.surfaceColor == surfaceColor &&
        other.onPrimaryColor == onPrimaryColor &&
        other.onSecondaryColor == onSecondaryColor &&
        other.onBackgroundColor == onBackgroundColor &&
        other.onSurfaceColor == onSurfaceColor &&
        other.errorColor == errorColor &&
        other.onErrorColor == onErrorColor &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        preset,
        mode,
        primaryColor,
        secondaryColor,
        backgroundColor,
        surfaceColor,
        onPrimaryColor,
        onSecondaryColor,
        onBackgroundColor,
        onSurfaceColor,
        errorColor,
        onErrorColor,
        isCustom,
      );
}
