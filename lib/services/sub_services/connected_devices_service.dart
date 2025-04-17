import 'dart:async';

import 'package:collection/collection.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

/// Service to manage wearable devices in the background isolate
class ConnectedDevicesService {
  // Wearable management
  final WearableManager _wearableManager = WearableManager();
  StreamSubscription? _scanSubscription;

  // Device state
  final List<DiscoveredDevice> _discoveredDevices = [];
  final Set<DiscoveredDevice> _connectingDevices = {};
  final Set<Wearable> _connectedDevices = {};

  // Stream controllers
  final StreamController<List<DiscoveredDevice>> _discoveredDevicesController = 
      StreamController<List<DiscoveredDevice>>.broadcast();
  final StreamController<Set<Wearable>> _connectedDevicesController = 
      StreamController<Set<Wearable>>.broadcast();
  
  // For the heart rate stream
  final Map<String, _HeartRateEntry> _heartRateMap = {};
  Timer? _heartRateResetTimer;
  final StreamController<int?> _heartRateStreamController =
      StreamController<int?>.broadcast();

  // Getters
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  Set<DiscoveredDevice> get connectingDevices => _connectingDevices;
  Set<Wearable> get connectedDevices => _connectedDevices;
  Stream<List<DiscoveredDevice>> get onDiscoveredDevicesChanged => _discoveredDevicesController.stream;
  Stream<Set<Wearable>> get onDevicesChanged => _connectedDevicesController.stream;
  Stream<int?> get heartRateStream => _heartRateStreamController.stream;

  ConnectedDevicesService() {
    _initialize();
  }

  void _initialize() {
    // Listen for new connected devices
    _wearableManager.connectStream.listen(_onDeviceConnected);

    // Listen for new connecting devices
    _wearableManager.connectingStream.listen((device) {
      _connectingDevices.add(device);
    },);
  }

  void _onDeviceConnected(Wearable wearable) {
    wearable.addDisconnectListener(() {
      if (_connectedDevices.any((device) => device.deviceId == wearable.deviceId)) {
        _connectedDevices.removeWhere((device) => device.deviceId == wearable.deviceId);
        _connectedDevicesController.add(_connectedDevices);
      }
    });

    // Enable heart rate sensors
    if (wearable is SensorManager) {
      for (Sensor sensor in (wearable as SensorManager).sensors) {
        // Enable heart rate and HRV sensors
        if (sensor is HeartRateSensor || sensor is HeartRateVariabilitySensor) {
          for (SensorConfiguration config in sensor.relatedConfigurations) {
            if (config is SensorFrequencyConfiguration) {
              config.setMaximumFrequency();
            }
          }
        }

        // Listen for heart rate updates
        if (sensor is HeartRateSensor) {
          StreamSubscription hrs = sensor.sensorStream.listen((heartRate) {
            _updateHeartRate(wearable.deviceId, heartRate.heartRateBpm);
          });
          wearable.addDisconnectListener(() {
            hrs.cancel();
          });
        }
      }
    }

    _connectingDevices.removeWhere((d) => d.id == wearable.deviceId);
    _connectedDevices.add(wearable);
    _connectedDevicesController.add(_connectedDevices);
  }

  void _updateHeartRate(String wearableId, int? heartRate) {
    final now = DateTime.now();
    if (heartRate == null) {
      _heartRateMap.remove(wearableId);
    } else {
      _heartRateMap[wearableId] = _HeartRateEntry(heartRate, now);
    }

    // Remove entries older than 2 seconds
    final threshold = DateTime.now().subtract(const Duration(seconds: 2));
    _heartRateMap.removeWhere((id, entry) => entry.timestamp.isBefore(threshold));

    if (_heartRateMap.isEmpty) {
      _heartRateStreamController.add(null);
    } else {
      final maxEntry = _heartRateMap.entries
          .reduce((a, b) => a.value.heartRate >= b.value.heartRate ? a : b);
      _heartRateStreamController.add(maxEntry.value.heartRate);
    }

    // Reset the 3-second timer that sends null if no new heart rate is received
    _heartRateResetTimer?.cancel();
    _heartRateResetTimer = Timer(const Duration(seconds: 3), () {
      _heartRateStreamController.add(null);
    });
  }

  /// Start scanning for new devices
  void startScanning() {
    _discoveredDevices.clear();

    _scanSubscription?.cancel();
    _wearableManager.startScan(excludeUnsupported: true);
    _scanSubscription = _wearableManager.scanStream.listen((incomingDevice) {
      if (incomingDevice.name.isNotEmpty &&
          !_discoveredDevices.any((device) => device.id == incomingDevice.id)) {
        _discoveredDevices.add(incomingDevice);
        _discoveredDevicesController.add(_discoveredDevices);
      }
    });
  }

  /// Connect to a device by ID and name
  Future<void> connectToDevice(String deviceId, String deviceName) async {
    // Check if already connected
    if (_connectedDevices.firstWhereOrNull((d) => d.deviceId == deviceId) != null) {
      return;
    }

    // Find the device in discovered devices
    final device = _discoveredDevices.firstWhereOrNull((d) => d.id == deviceId);
    if (device != null) {
      await _wearableManager.connectToDevice(device);
    }
  }

  /// Set auto-connect devices
  void setAutoConnectDevices(List<String> deviceIds) {
    _wearableManager.setAutoConnect(deviceIds);
  }

  void dispose() {
    _scanSubscription?.cancel();
    _heartRateResetTimer?.cancel();
    _discoveredDevicesController.close();
    _connectedDevicesController.close();
    _heartRateStreamController.close();
  }
}

class _HeartRateEntry {
  final int heartRate;
  final DateTime timestamp;

  _HeartRateEntry(this.heartRate, this.timestamp);
}