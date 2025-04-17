import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/connected_device_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/auto_connect_device.dart';

class ScanView extends StatelessWidget {
  final bool enableManualConnectionChange;

  const ScanView({
    Key? key,
    this.enableManualConnectionChange = true,
  }) : super(key: key);

  List<Widget> _buildCombinedDeviceList(
    BuildContext context,
    SettingsController settingsController,
    ConnectedDeviceController connectedDeviceController,
    bool enableManualConnectionChange,
  ) {
    final List<Widget> result = [];

    final autoConnectDevices = settingsController.autoConnectDevices ?? [];
    final autoConnectIds = autoConnectDevices.map((d) => d.id).toSet();
    final Map<String, dynamic> discoveredMap = {
      for (var d in connectedDeviceController.discoveredDevices) d['id']: d,
    };

    // Build auto connect devices section
    for (int i = 0; i < autoConnectDevices.length; i++) {
      final autoDevice = autoConnectDevices[i];
      Widget tile;
      if (discoveredMap.containsKey(autoDevice.id)) {
        tile = _InteractiveTile(
          device: discoveredMap[autoDevice.id],
          enableManualConnectionChange: enableManualConnectionChange,
          autoConnectDevice: true,
        );
      } else {
        tile = _AutoConnectTile(device: autoDevice);
      }
      result.add(tile);
      result.add(
        const Divider(
          height: 1.0,
          thickness: 1.0,
          color: Colors.grey,
          indent: 8.0,
          endIndent: 8.0,
        ),
      );
    }

    // Build remaining discovered devices section (those not matching any auto connect device)
    final remainingDiscoveredDevices = connectedDeviceController
        .discoveredDevices
        .where((d) => !autoConnectIds.contains(d['id']))
        .toList();
    for (int i = 0; i < remainingDiscoveredDevices.length; i++) {
      final device = remainingDiscoveredDevices[i];
      result.add(
        _InteractiveTile(
          device: device,
          enableManualConnectionChange: enableManualConnectionChange,
        ),
      );
      result.add(
        const Divider(
          height: 1.0,
          thickness: 1.0,
          color: Colors.grey,
          indent: 8.0,
          endIndent: 8.0,
        ),
      );
    }

    if (result.isNotEmpty) {
      result.removeLast();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final connectedDeviceController =
        Provider.of<ConnectedDeviceController>(context);
    final settingsController = Provider.of<SettingsController>(context);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(33, 16, 33, 16),
          child: Text(
            "SCANNED DEVICES",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ),
        Visibility(
          visible:
              (settingsController.autoConnectDevices?.isNotEmpty ?? false) ||
                  connectedDeviceController.discoveredDevices.isNotEmpty,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: _buildCombinedDeviceList(
                context,
                settingsController,
                connectedDeviceController,
                enableManualConnectionChange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: connectedDeviceController.startScanning,
            child: const Text('Restart Scan'),
          ),
        ),
      ],
    );
  }
}

class _AutoConnectTile extends StatelessWidget {
  final AutoConnectDevice device;

  const _AutoConnectTile({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      textColor: Colors.black54,
      selectedTileColor: Colors.grey,
      title: Text(
        device.name,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
      titleTextStyle:
          const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      trailing: const Icon(Icons.auto_awesome, size: 24, color: Colors.blue),
      // No onTap action
    );
  }
}

class _InteractiveTile extends StatelessWidget {
  final Map<String, dynamic> device;
  final bool enableManualConnectionChange;
  final bool autoConnectDevice;

  const _InteractiveTile({
    Key? key,
    required this.device,
    required this.enableManualConnectionChange,
    this.autoConnectDevice = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectedDeviceController =
        Provider.of<ConnectedDeviceController>(context, listen: false);
    Widget trailing;
    if (connectedDeviceController.connectedDevices
        .any((e) => e['deviceId'] == device['id'])) {
      trailing = const Icon(size: 24, Icons.check, color: Colors.green);
    } else if (connectedDeviceController.connectingDevices
        .any((e) => e['id'] == device['id'])) {
      trailing = const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      trailing = autoConnectDevice
          ? const Icon(Icons.auto_awesome, size: 24, color: Colors.blue)
          : const SizedBox.shrink();
    }

    return ListTile(
      textColor: enableManualConnectionChange ? Colors.black : Colors.black54,
      selectedTileColor: Colors.grey,
      title: Text(device['name'] ?? ''),
      titleTextStyle: const TextStyle(fontSize: 16),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      trailing: trailing,
      onTap: enableManualConnectionChange
          ? () {
              connectedDeviceController.connectToDevice(device);
            }
          : null,
    );
  }
}
