import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble_provider.dart';
import 'screens/device_list_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BLEProvider()..startScan(),
      child: const FinderApp(),
    ),
  );
}

class FinderApp extends StatelessWidget {
  const FinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const DeviceListScreen(),
    );
  }
}
