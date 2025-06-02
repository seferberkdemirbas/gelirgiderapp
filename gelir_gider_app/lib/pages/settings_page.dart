// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema Modu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sistem'),
              value: ThemeMode.system,
              groupValue: prov.themeMode,
              onChanged: (mode) {
                if (mode != null) prov.setThemeMode(mode);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Açık'),
              value: ThemeMode.light,
              groupValue: prov.themeMode,
              onChanged: (mode) {
                if (mode != null) prov.setThemeMode(mode);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Koyu'),
              value: ThemeMode.dark,
              groupValue: prov.themeMode,
              onChanged: (mode) {
                if (mode != null) prov.setThemeMode(mode);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Tema Rengi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 12,
              children: [
                _colorTile(context, Colors.blue, prov),
                _colorTile(context, Colors.red, prov),
                _colorTile(context, Colors.green, prov),
                _colorTile(context, Colors.orange, prov),
                _colorTile(context, Colors.purple, prov),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorTile(BuildContext ctx, MaterialColor color, ThemeProvider prov) {
    final selected = prov.primarySwatch == color;
    return GestureDetector(
      onTap: () => prov.setPrimarySwatch(color),
      child: CircleAvatar(
        backgroundColor: color,
        radius: selected ? 22 : 18,
        child: selected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
