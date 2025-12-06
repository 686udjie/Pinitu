import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pin.dart';
import '../widgets/pin_tile.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<PinItem> _savedPins = <PinItem>[];

  @override
  void initState() {
    super.initState();
    _loadSavedPins();
  }

  Future<void> _loadSavedPins() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getStringList('saved_pins_json') ?? [];
    final pins = savedJson.map((json) => PinItem.fromJson(jsonDecode(json))).toList();
    setState(() => _savedPins = pins);
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    if (_savedPins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No saved pins yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = _getCrossAxisCount(context);

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: _savedPins.length,
      itemBuilder: (context, index) {
        final pin = _savedPins[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PinTile(pin: pin),
        );
      },
    );
  }
}