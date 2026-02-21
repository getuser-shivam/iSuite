import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() =>
      _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme Mode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildThemeModeSelector(themeProvider),
                const SizedBox(height: 32),
                const Text(
                  'Preset Themes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPresetThemes(themeProvider),
                const SizedBox(height: 32),
                const Text(
                  'Custom Colors',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildCustomColors(themeProvider),
                const SizedBox(height: 32),
                const Text(
                  'Theme Preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildThemePreview(themeProvider),
              ],
            ),
          ),
        ),
      );

  Widget _buildThemeModeSelector(ThemeProvider themeProvider) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Select Theme Mode'),
              const SizedBox(height: 16),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildColorSelector(
              'Primary Color',
              currentTheme.primaryColor,
              (color) => themeProvider.updateCustomColors(primaryColor: color),
            ),
            const SizedBox(height: 16),
            _buildColorSelector(
              'Secondary Color',
              currentTheme.secondaryColor,
              (color) =>
                  themeProvider.updateCustomColors(secondaryColor: color),
            ),
            const SizedBox(height: 16),
            _buildColorSelector(
              'Background Color',
              currentTheme.backgroundColor,
              (color) =>
                  themeProvider.updateCustomColors(backgroundColor: color),
            ),
            const SizedBox(height: 16),
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
        const SizedBox(height: 8),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Preview',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Sample app bar
              Container(
                height: 56,
                color: themeProvider.currentTheme.primaryColor,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'App Bar',
                  style: TextStyle(
                    color: themeProvider.currentTheme.onPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sample card
              Container(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 8),
                    Text(
                      'This is how your theme will look.',
                      style: TextStyle(
                        color: themeProvider.currentTheme.onSurfaceColor
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 8),
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
