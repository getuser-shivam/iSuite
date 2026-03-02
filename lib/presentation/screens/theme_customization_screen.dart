import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../../core/constants.dart';
import '../../core/config/central_config.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() =>
      _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  late ThemeProvider _themeProvider;
  late CentralConfig _config;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _config = CentralConfig.instance;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Theme Customization'),
          actions: [
            IconButton(
              onPressed: () => _themeProvider.resetToDefault(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to Default',
            ),
          ],
        ),
        body: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => SingleChildScrollView(
            padding: EdgeInsets.all(_config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.theme_title_font_size', defaultValue: AppConstants.THEME_TITLE_FONT_SIZE),
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildThemeModeSelector(themeProvider),
                SizedBox(height: _config.getParameter('ui.large_spacing', defaultValue: AppConstants.LARGE_SPACING.toDouble())),
                Text(
                  'Preset Themes',
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.theme_title_font_size', defaultValue: AppConstants.THEME_TITLE_FONT_SIZE),
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildPresetThemes(themeProvider),
                SizedBox(height: _config.getParameter('ui.large_spacing', defaultValue: AppConstants.LARGE_SPACING.toDouble())),
                Text(
                  'Custom Colors',
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.theme_title_font_size', defaultValue: AppConstants.THEME_TITLE_FONT_SIZE),
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildCustomColors(themeProvider),
                SizedBox(height: _config.getParameter('ui.large_spacing', defaultValue: AppConstants.LARGE_SPACING.toDouble())),
                Text(
                  'Theme Preview',
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.theme_title_font_size', defaultValue: AppConstants.THEME_TITLE_FONT_SIZE),
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildThemePreview(themeProvider),
              ],
            ),
          ),
        ),
      );

  Widget _buildThemeModeSelector(ThemeProvider themeProvider) => Card(
        child: Padding(
          padding: EdgeInsets.all(_config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble())),
          child: Column(
            children: [
              const Text('Select Theme Mode'),
              SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton(themeProvider, ThemeMode.light, 'Light'),
                  _buildModeButton(themeProvider, ThemeMode.dark, 'Dark'),
                  _buildModeButton(themeProvider, ThemeMode.system, 'System'),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildModeButton(
      ThemeProvider themeProvider, ThemeMode mode, String label) {
    final isSelected = themeProvider.themeMode == mode;
    return ElevatedButton(
      onPressed: () => themeProvider.setThemeMode(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Theme.of(context).colorScheme.primary : null,
        foregroundColor:
            isSelected ? Theme.of(context).colorScheme.onPrimary : null,
      ),
      child: Text(label),
    );
  }

  Widget _buildPresetThemes(ThemeProvider themeProvider) {
    final presets = themeProvider.availablePresets;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _config.getParameter('ui.theme_grid_cross_axis_count', defaultValue: AppConstants.THEME_GRID_CROSS_AXIS_COUNT),
        crossAxisSpacing: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble()),
        mainAxisSpacing: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble()),
        childAspectRatio: _config.getParameter('ui.theme_grid_aspect_ratio', defaultValue: AppConstants.THEME_GRID_ASPECT_RATIO),
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isSelected = themeProvider.currentTheme.preset == preset.preset;

        return GestureDetector(
          onTap: () => themeProvider.setPresetTheme(preset.preset),
          child: Container(
            decoration: BoxDecoration(
              color: preset.primaryColor,
              borderRadius: BorderRadius.circular(_config.getParameter('ui.card_radius', defaultValue: AppConstants.CARD_RADIUS.toDouble())),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      color: preset.onPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: _config.getParameter('ui.theme_color_indicator_size', defaultValue: AppConstants.THEME_COLOR_INDICATOR_SIZE),
                    height: _config.getParameter('ui.theme_color_indicator_size', defaultValue: AppConstants.THEME_COLOR_INDICATOR_SIZE),
                    decoration: BoxDecoration(
                      color: preset.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: _config.getParameter('ui.theme_preview_icon_size', defaultValue: AppConstants.THEME_PREVIEW_ICON_SIZE),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomColors(ThemeProvider themeProvider) {
    final currentTheme = themeProvider.currentTheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(_config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble())),
        child: Column(
          children: [
            _buildColorSelector(
              'Primary Color',
              currentTheme.primaryColor,
              (color) => themeProvider.updateCustomColors(primaryColor: color),
            ),
            SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
            _buildColorSelector(
              'Secondary Color',
              currentTheme.secondaryColor,
              (color) =>
                  themeProvider.updateCustomColors(secondaryColor: color),
            ),
            SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
            _buildColorSelector(
              'Background Color',
              currentTheme.backgroundColor,
              (color) =>
                  themeProvider.updateCustomColors(backgroundColor: color),
            ),
            SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
            _buildColorSelector(
              'Surface Color',
              currentTheme.surfaceColor,
              (color) => themeProvider.updateCustomColors(surfaceColor: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(
      String label, Color currentColor, Function(Color) onColorChanged) {
    final presetColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.white,
      Colors.black,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: _config.getParameter('ui.small_spacing', defaultValue: AppConstants.SMALL_SPACING.toDouble())),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetColors.map((color) {
            final isSelected = color == currentColor;
            return GestureDetector(
              onTap: () => onColorChanged(color),
              child: Container(
                width: _config.getParameter('ui.color_selector_size', defaultValue: AppConstants.COLOR_SELECTOR_SIZE),
                height: _config.getParameter('ui.color_selector_size', defaultValue: AppConstants.COLOR_SELECTOR_SIZE),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: _config.getParameter('ui.small_icon_size', defaultValue: AppConstants.SMALL_ICON_SIZE.toDouble()),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemePreview(ThemeProvider themeProvider) => Card(
        child: Padding(
          padding: EdgeInsets.all(_config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble())),
          child: Column(
            children: [
              const Text('Preview',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
              // Sample app bar
              Container(
                height: _config.getParameter('ui.theme_preview_height', defaultValue: AppConstants.THEME_PREVIEW_HEIGHT),
                color: themeProvider.currentTheme.primaryColor,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(
                  horizontal: _config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble()),
                ),
                child: Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.font_size_medium', defaultValue: AppConstants.FONT_SIZE_MEDIUM.toDouble()),
                    color: themeProvider.currentTheme.onPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
              // Sample card
              Container(
                padding: EdgeInsets.all(_config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble())),
                decoration: BoxDecoration(
                  color: themeProvider.currentTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(_config.getParameter('ui.button_radius', defaultValue: AppConstants.BUTTON_RADIUS.toDouble())),
                  border: Border.all(
                      color: themeProvider.currentTheme.primaryColor
                          .withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Card',
                      style: TextStyle(
                        color: themeProvider.currentTheme.onSurfaceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: _config.getParameter('ui.small_spacing', defaultValue: AppConstants.SMALL_SPACING.toDouble())),
                    Text(
                      'This is how your theme will look.',
                      style: TextStyle(
                        color: themeProvider.currentTheme.onSurfaceColor
                            .withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeProvider.currentTheme.primaryColor,
                            foregroundColor:
                                themeProvider.currentTheme.onPrimaryColor,
                          ),
                          child: const Text('Primary'),
                        ),
                        SizedBox(width: _config.getParameter('ui.small_spacing', defaultValue: AppConstants.SMALL_SPACING.toDouble())),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    themeProvider.currentTheme.secondaryColor),
                          ),
                          child: Text(
                            'Secondary',
                            style: TextStyle(
                                color:
                                    themeProvider.currentTheme.secondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
