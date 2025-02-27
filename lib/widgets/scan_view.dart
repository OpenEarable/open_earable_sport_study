import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/connected_device_controller.dart';

class ScanView extends StatelessWidget {
  const ScanView({Key? key}) : super(key: key);

  Widget _buildTrailingWidget(BuildContext context, String id) {
    final controller = Provider.of<ConnectedDeviceController>(context);
    if (controller.connectedDevices.any((e) => e.deviceId == id)) {
      return const Icon(size: 24, Icons.check, color: Colors.green);
    } else if (controller.connectingDevices.any((e) => e.id == id)) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConnectedDeviceController>(context);
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(33, 16, 0, 0),
          child: Text(
            "SCANNED DEVICES",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ),
        Visibility(
          visible: controller.discoveredDevices.isNotEmpty,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.discoveredDevices.length,
              itemBuilder: (BuildContext context, int index) {
                final device = controller.discoveredDevices[index];
                return Column(
                  children: [
                    ListTile(
                      textColor: Colors.black,
                      selectedTileColor: Colors.grey,
                      title: Text(device.name),
                      titleTextStyle: const TextStyle(fontSize: 16),
                      visualDensity:
                          const VisualDensity(horizontal: -4, vertical: -4),
                      trailing: _buildTrailingWidget(context, device.id),
                      onTap: () {
                        controller.connectToDevice(device);
                      },
                    ),
                    if (index != controller.discoveredDevices.length - 1)
                      const Divider(
                        height: 1.0,
                        thickness: 1.0,
                        color: Colors.grey,
                        indent: 16.0,
                        endIndent: 0.0,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Center(
          child: ElevatedButton(
            onPressed: controller.startScanning,
            child: const Text('Restart Scan'),
          ),
        ),
      ],
    );
  }
}
