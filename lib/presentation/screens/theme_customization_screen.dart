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
                const Text(
                  'Theme Mode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildThemeModeSelector(themeProvider),
                SizedBox(height: _config.getParameter('ui.large_spacing', defaultValue: AppConstants.LARGE_SPACING.toDouble())),
                const Text(
                  'Preset Themes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildPresetThemes(themeProvider),
                SizedBox(height: _config.getParameter('ui.large_spacing', defaultValue: AppConstants.LARGE_SPACING.toDouble())),
                const Text(
                  'Custom Colors',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble())),
                _buildCustomColors(themeProvider),
                SizedBox(height: _config.getParameter('ui.large_spacing', defaultValue: AppConstants.LARGE_SPACING.toDouble())),
                const Text(
                  'Theme Preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        crossAxisCount: 2,
        crossAxisSpacing: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble()),
        mainAxisSpacing: _config.getParameter('ui.default_spacing', defaultValue: AppConstants.DEFAULT_SPACING.toDouble()),
        childAspectRatio: 1.5,
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
              borderRadius: BorderRadius.circular(12),
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
                    width: 24,
                    height: 24,
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
                      size: 24,
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
                width: 40,
                height: 40,
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
                        size: 20,
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
                height: 56,
                color: themeProvider.currentTheme.primaryColor,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: _config.getParameter('ui.default_padding', defaultValue: AppConstants.DEFAULT_PADDING.toDouble())),
                child: Text(
                  'App Bar',
                  style: TextStyle(
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
                  borderRadius: BorderRadius.circular(8),
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
