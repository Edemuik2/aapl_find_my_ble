import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ble_provider.dart';
import 'radar_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Устройства рядом",
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ble.scanResults.isEmpty
          ? const Center(
              child: Text(
                "Поиск устройств...",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: ble.scanResults.length,
              itemBuilder: (context, index) {
                final result = ble.scanResults[index];
                return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // ИСПРАВЛЕНО: используем withValues вместо устаревшего withOpacity
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(result.device.platformName),
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          result.device.platformName.isNotEmpty
                              ? result.device.platformName
                              : "Unknown Device",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          "Сигнал: ${result.rssi} dBm",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white24,
                        ),
                        onTap: () {
                          context.read<BLEProvider>().selectDevice(
                            result.device,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RadarScreen(),
                            ),
                          );
                        },
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                    .slideX(begin: 0.2, end: 0); // Плавный выезд сбоку
              },
            ),
    );
  }

  IconData _getIcon(String name) {
    final lowerName = name.toLowerCase();

    // ИСПРАВЛЕНО: добавлены обязательные фигурные скобки для соответствия правилам Dart
    if (lowerName.contains("iphone")) {
      return Icons.phone_iphone;
    }

    if (lowerName.contains("airpods") ||
        lowerName.contains("headset") ||
        lowerName.contains("buds")) {
      return Icons.headphones;
    }

    if (lowerName.contains("watch")) {
      return Icons.watch;
    }

    return Icons.bluetooth;
  }
}
