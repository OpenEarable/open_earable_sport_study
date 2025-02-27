import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

class ConnectedDeviceController extends ChangeNotifier {
  final WearableManager _wearableManager = WearableManager();
  StreamSubscription? _scanSubscription;

  // Device state
  List<DiscoveredDevice> discoveredDevices = [];
  Set<DiscoveredDevice> connectingDevices = {};
  Set<Wearable> connectedDevices = {};

  ConnectedDeviceController() {
    startScanning();
  }

  // Start scanning and update the list of discovered devices.
  void startScanning() {
    _scanSubscription?.cancel();
    _wearableManager.startScan(excludeUnsupported: true);
    _scanSubscription = _wearableManager.scanStream.listen((incomingDevice) {
      if (incomingDevice.name.isNotEmpty &&
          !discoveredDevices.any((device) => device.id == incomingDevice.id)) {
        discoveredDevices.add(incomingDevice);
        notifyListeners();
      }
    });
  }

  // Connect to a device and set up disconnect listeners.
  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (connectedDevices.firstWhereOrNull((d) => d.deviceId == device.id) !=
        null) {
      return;
    }

    connectingDevices.add(device);
    notifyListeners();

    _scanSubscription?.cancel();
    Wearable wearable = await _wearableManager.connectToDevice(device);
    wearable.addDisconnectListener(() {
      if (connectedDevices
          .any((device) => device.deviceId == wearable.deviceId)) {
        connectedDevices
            .removeWhere((device) => device.deviceId == wearable.deviceId);
        notifyListeners();
      }
    });

    connectingDevices.removeWhere((d) => d.id == device.id);
    connectedDevices.add(wearable);
    notifyListeners();
  }
}
