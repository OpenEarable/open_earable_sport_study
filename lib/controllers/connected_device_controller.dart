import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

import '../models/auto_connect_device.dart';
import '../services/background_service.dart';
import 'settings_controller.dart';

class ConnectedDeviceController extends ChangeNotifier {
  late final SettingsController _settingsController;
  final BackgroundServiceManager _backgroundService = BackgroundServiceManager.instance;

  // Device state
  final List<Map<String, dynamic>> _discoveredDevices = [];
  final Set<String> _connectingDeviceIds = {};
  final Set<Map<String, dynamic>> _connectedDevices = {};

  // Stream subscriptions
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _discoveredDevicesSubscription;

  // For the heart rate stream
  final StreamController<int?> _heartRateStreamController =
      StreamController<int?>.broadcast();

  // Getters for UI
  List<Map<String, dynamic>> get discoveredDevices => _discoveredDevices;
  Set<Map<String, dynamic>> get connectedDevices => _connectedDevices;
  bool get hasConnectingDevices => _connectingDeviceIds.isNotEmpty;
  Stream<int?> get heartRateStream => _heartRateStreamController.stream;

  // Lock state for auto-reconnect functionality
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  void setLock(bool value) {
    _isLocked = value;
    notifyListeners();
  }

  ConnectedDeviceController({required SettingsController settingsController}) {
    _settingsController = settingsController;

    _settingsController.addListener(_onSettingsChanged);
    
    _initBackgroundService();
  }
  
  Future<void> _initBackgroundService() async {
    // Request permissions for the background service
    await _backgroundService.requestPermissions();
    
    // Subscribe to device state changes from the background service
    _devicesSubscription = _backgroundService.connectedDevicesStream.listen(_handleDevicesUpdate);
    
    // Subscribe to heart rate updates from the background service
    _heartRateSubscription = _backgroundService.heartRateStream.listen(
      (value) => _heartRateStreamController.add(value as int?),
    );
    
    // Subscribe to discovered devices from the background service
    _discoveredDevicesSubscription = _backgroundService.discoveredDevicesStream.listen(_handleDiscoveredDevices);
    
    // Start the background service if not already running
    if (!await _backgroundService.isServiceRunning()) {
      await _backgroundService.startService();
    }
    
    // Initialize scanning
    startScanning();
  }
  
  void _handleDevicesUpdate(List<Map<String, dynamic>> devices) {
    _connectedDevices.clear();
    _connectedDevices.addAll(devices.toSet());
    
    // Update connecting devices set
    _connectingDeviceIds.removeWhere((id) => 
      _connectedDevices.any((device) => device['id'] == id),);
    
    notifyListeners();
    
    // Auto-connect functionality
    if (_settingsController.autoConnectDevices != null && !_isLocked) {
      persistConnectedDevicesForAutoConnect();
    }
  }
  
  void _handleDiscoveredDevices(List<Map<String, dynamic>> devices) {
    print('ConnectedDeviceController: Received ${devices.length} discovered devices');
    for (var device in devices) {
      print('  Device: ${device['name']} (${device['id']})');
    }
    
    _discoveredDevices.clear();
    _discoveredDevices.addAll(devices);
    print('ConnectedDeviceController: Total discovered devices: ${_discoveredDevices.length}');
    notifyListeners();
  }

  void _onSettingsChanged() {
    // Send auto-connect devices to background service
    if (_settingsController.autoConnectDevices != null) {
      final deviceIds = _settingsController.autoConnectDevices
          ?.map((device) => device.id)
          .toList() ?? [];
          
      // This will be handled by the background service
      _backgroundService.sendCommand('setAutoConnectDevices', {
        'deviceIds': deviceIds,
      },);
    }
  }

  /// Persist the list of connected devices for auto-connect functionality.
  void persistConnectedDevicesForAutoConnect() {
    _settingsController.setAutoConnectDevices(
      _connectedDevices
          .map(
            (device) => AutoConnectDevice(
              id: device['id'] as String,
              name: device['name'] as String,
            ),
          )
          .toList(),
    );
  }

  /// Start scanning and update the list of discovered devices.
  void startScanning() {
    print('ConnectedDeviceController: Starting scan...');
    _discoveredDevices.clear();
    
    // Try both approaches - background service and direct scanning
    _backgroundService.startScanning();
    _startDirectScanning();
    
    notifyListeners();
  }
  
  /// Direct scanning without using the background service - for testing
  void _startDirectScanning() {
    print('ConnectedDeviceController: Starting DIRECT scan...');
    
    // Create a direct instance of WearableManager for testing
    final wearableManager = WearableManager();
    wearableManager.startScan(excludeUnsupported: true);
    
    wearableManager.scanStream.listen((device) {
      print('ConnectedDeviceController: DIRECT scan found device: ${device.name} (${device.id})');
      if (!_discoveredDevices.any((d) => d['id'] == device.id)) {
        final deviceMap = {
          'id': device.id,
          'name': device.name,
          'rssi': device.rssi,
          'type': device.runtimeType.toString(),
        };
        _discoveredDevices.add(deviceMap);
        print('ConnectedDeviceController: Added device to discovered list, total: ${_discoveredDevices.length}');
        notifyListeners();
      }
    });
  }

  /// Connect to a device.
  Future<void> connectToDevice(Map<String, dynamic> device) async {
    if (_connectedDevices.any((d) => d['id'] == device['id'])) {
      return;
    }
    
    // Add to connecting devices set
    _connectingDeviceIds.add(device['id'] as String);
    notifyListeners();
    
    // Send command to background service
    _backgroundService.connectToDevice(
      device['id'] as String,
      device['name'] as String,
    );
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    _devicesSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _discoveredDevicesSubscription?.cancel();
    _heartRateStreamController.close();
    super.dispose();
  }
}

