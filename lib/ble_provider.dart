import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BLEProvider extends ChangeNotifier {
  List<ScanResult> scanResults = [];
  BluetoothDevice? targetDevice;
  int? lastRSSI;
  double distance = 0.0;
  double deviceHeading = 0.0; // Куда смотрит телефон
  double targetAzimuth = 0.0; // Где находится цель (запоминаем лучший RSSI)
  int maxRSSI = -100;

  StreamSubscription? _scanSub;
  StreamSubscription? _compassSub;
  @override
  void dispose() {
    _scanSub?.cancel();
    _compassSub?.cancel(); // Теперь переменная используется
    super.dispose();
  }

  BLEProvider() {
    _initCompass();
  }

  void startScan() {
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: true,
    );
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results
          .where((r) => r.device.platformName.isNotEmpty)
          .toList();
      notifyListeners();
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
  }

  void selectDevice(BluetoothDevice device) {
    targetDevice = device;
    maxRSSI = -100;
    _startTracking();
  }

  // Добавляем ключевое слово async перед открывающей скобкой
  void _startTracking() async {
    // Убираем appleAllowDuplicates, так как он часто вызывает конфликты в новых версиях
    // Если нужно постоянное обновление на iOS, используется continuousUpdates
    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true, // Замена для получения постоянных данных RSSI
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.remoteId == targetDevice!.remoteId) {
          lastRSSI = r.rssi;
          distance = _calculateDistance(r.rssi);

          if (r.rssi > maxRSSI) {
            maxRSSI = r.rssi;
            targetAzimuth = deviceHeading;
          }
          notifyListeners();
        }
      }
    });
  }

  void _initCompass() {
    // Упрощенный расчет направления по магнитометру
    magnetometerEventStream().listen((event) {
      double heading = atan2(event.y, event.x) * (180 / pi);
      deviceHeading = heading < 0 ? heading + 360 : heading;
      notifyListeners();
    });
  }

  double _calculateDistance(int rssi) {
    // Формула: d = 10 ^ ((MeasuredPower - RSSI) / (10 * N))
    int txPower = -59;
    return pow(10, ((txPower - rssi) / (10 * 2.2))).toDouble();
  }

  void reset() {
    targetDevice = null;
    stopScan();
    startScan();
    notifyListeners();
  }
}
