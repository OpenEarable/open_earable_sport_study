import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/connected_device_controller.dart';
import 'connected_devices_page.dart';
import 'settings_page.dart';
import '../widgets/wearable_info_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConnectedDeviceController>(context);
    final devices = controller.connectedDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'connected') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectedDevicesPage(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'connected',
                child: Text('Connected Devices'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: devices.isEmpty
              ? const Center(
                  child: Wrap(
                    children: [
                      Text("Please connect at least one device (use the menu)"),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: devices
                      .map(
                        (device) => Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: WearableInfoWidget(
                            key: Key(device.deviceId),
                            wearable: device,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }
}
