import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

class ConnectedDeviceSubService {
  final List<Map<String, dynamic>> discoveredDevices = [];
  final List<Map<String, dynamic>> connectedDevices = [];
  OpenEarable? _openEarable;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<Wearable>? _connectionSubscription;

  ConnectedDeviceSubService() {
    _openEarable = OpenEarable();
  }

  void startScanning() {
    discoveredDevices.clear();
    _scanSubscription?.cancel();
    _scanSubscription = _openEarable!.scan().listen((device) {
      final deviceMap = {
        'id': device.id,
        'name': device.name,
        'deviceId': device.id,
        'rssi': device.rssi,
      };
      if (!discoveredDevices.any((d) => d['id'] == device.id)) {
        discoveredDevices.add(deviceMap);
        sendDeviceStatusUpdate();
      }
    });
    sendDeviceStatusUpdate();
  }

  void connect(dynamic params) async {
    final String deviceId = params['id'] ?? params['deviceId'];
    final device = discoveredDevices.firstWhere(
      (d) => d['id'] == deviceId,
      orElse: () => {},
    );
    if (device.isEmpty) return;
    _connectionSubscription?.cancel();
    _connectionSubscription = _openEarable!
        .connectToDevice(deviceId)
        .listen((wearable) {
      final wearableMap = {
        'id': wearable.deviceId,
        'name': wearable.name,
        'deviceId': wearable.deviceId,
        // Add more fields if needed
      };
      if (!connectedDevices.any((d) => d['id'] == wearable.deviceId)) {
        connectedDevices.add(wearableMap);
        sendDeviceStatusUpdate();
      }
    });
  }

  void sendDeviceStatusUpdate() {
    FlutterForegroundTask.sendDataToMain({
      'type': 'deviceStatus',
      'data': {
        'discoveredDevices': discoveredDevices,
        'connectedDevices': connectedDevices,
      },
    });
  }
}
