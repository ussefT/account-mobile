import 'package:flutter/material.dart';

import 'settings_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: controller.themeMode == ThemeMode.dark,
                      onChanged: (v) {
                        controller.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                      },
                      title: const Text('Dark theme'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Font size',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview text size',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: controller.textScale,
                      min: 0.8,
                      max: 1.6,
                      divisions: 8,
                      label: controller.textScale.toStringAsFixed(1),
                      onChanged: controller.setTextScale,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

