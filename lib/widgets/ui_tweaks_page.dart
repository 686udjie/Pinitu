import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_provider.dart';

class UITweaksPage extends StatelessWidget {
  const UITweaksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Tweaks'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Hide navbar items labels'),
            value: themeProvider.hideNavbarLabels,
            onChanged: (value) => themeProvider.setHideNavbarLabels(value),
          ),
        ],
      ),
    );
  }
}