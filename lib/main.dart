import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'core/di/injection.dart';
import 'presentation/screens/converter_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup window for desktop platforms
  final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  if (isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(400, 800),
      minimumSize: Size(360, 720),
      maximumSize: Size(480, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  // Setup dependency injection
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1F2E),
        primaryColor: const Color(0xFF2D3548),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B7FFF),
          surface: Color(0xFF252B3D),
          background: Color(0xFF1A1F2E),
        ),
      ),
      home: const ConverterScreen(),
    );
  }
}
