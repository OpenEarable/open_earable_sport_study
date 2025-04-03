import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/connected_device_controller.dart';
import '../widgets/wearable_info_widget.dart';

class WearableInfoListWidget extends StatelessWidget {
  const WearableInfoListWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConnectedDeviceController>(context);
    final devices = controller.connectedDevices;

    return devices.isEmpty
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
            (device) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: WearableInfoWidget(
                key: Key(device.deviceId),
                wearable: device,
              ),
            ),
      )
          .toList(),
    );
  }
}
