import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/home_page.dart';
import 'services/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const PinituApp(),
    ),
  );
}

class PinituApp extends StatelessWidget {
  const PinituApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Pinitu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const HomePage(),
    );
  }
}
