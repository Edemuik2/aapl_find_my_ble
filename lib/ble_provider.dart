import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer; // Импорт для логирования
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
    _compassSub?.cancel();
    super.dispose();
  }

  BLEProvider() {
    _initCompass();
  }

  // Метод остановки сканирования (ИСПРАВЛЕНО: добавлен)
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
  }

  void startScan() async {
    // 1. ПРИНУДИТЕЛЬНО просим права на Геопозицию и Bluetooth
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // Если пользователь отказал — выходим (ИСПРАВЛЕНО: замена print на log)
    if (statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
      developer.log("Доступ к геопозиции отклонен");
      return;
    }

    // 2. Проверяем состояние адаптера
    var state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      developer.log("Bluetooth выключен");
      return;
    }

    scanResults.clear();
    notifyListeners();

    try {
      // ИСПРАВЛЕНО: удален параметр appleAllowDuplicates (устарел)
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        // Сортировка по силе сигнала
        results.sort((a, b) => b.rssi.compareTo(a.rssi));
        scanResults = results;
        notifyListeners();
      }, onError: (e) => developer.log("Ошибка стрима: $e"));
    } catch (e) {
      developer.log("Ошибка старта сканирования: $e");
    }
  }

  void selectDevice(BluetoothDevice device) {
    targetDevice = device;
    maxRSSI = -100;
    _startTracking();
  }

  void _startTracking() async {
    // Для трекинга конкретного устройства используем continuousUpdates
    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true,
    );

    _scanSub?.cancel();
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
    _compassSub = magnetometerEventStream().listen((event) {
      double heading = atan2(event.y, event.x) * (180 / pi);
      deviceHeading = heading < 0 ? heading + 360 : heading;
      notifyListeners();
    });
  }

  double _calculateDistance(int rssi) {
    // Константа для iPhone/Android (мощность сигнала на 1 метре)
    int txPower = -59;
    if (rssi == 0) return -1.0;

    double ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) {
      return pow(ratio, 10).toDouble();
    } else {
      return (0.89976) * pow(ratio, 7.7095) + 0.111;
    }
  }

  void reset() {
    targetDevice = null;
    stopScan(); // Теперь метод существует
    notifyListeners();
  }
}
