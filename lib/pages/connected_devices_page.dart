import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/connected_device_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/scan_view.dart';

class ConnectedDevicesPage extends StatelessWidget {
  const ConnectedDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final connectedDevicesController =
        Provider.of<ConnectedDeviceController>(context);
    final settingsController = Provider.of<SettingsController>(context);

    bool lockedConnections =
        settingsController.autoConnectDevices?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected Devices"),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    lockedConnections ? Icons.lock : Icons.lock_open,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lockedConnections
                        ? "Auto-(Re-)Connect ON"
                        : "Auto-(Re-)Connect OFF",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: lockedConnections,
                    onChanged: (bool value) {
                      if (value) {
                        connectedDevicesController
                            .persistConnectedDevicesForAutoConnect();
                      } else {
                        settingsController.setAutoConnectDevices(null);
                      }
                      connectedDevicesController.setLock(value);
                    },
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ScanView(
                  enableManualConnectionChange: !lockedConnections,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
