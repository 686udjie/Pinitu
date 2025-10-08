import 'package:flutter/material.dart';
import 'widgets/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PinituApp());
}

class PinituApp extends StatelessWidget {
  const PinituApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinitu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      home: const HomePage(),
    );
  }
}