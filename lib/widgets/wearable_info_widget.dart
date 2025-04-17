import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'grouped_box.dart';

class WearableInfoWidget extends StatefulWidget {
  final Map<String, dynamic> deviceInfo;

  const WearableInfoWidget({
    Key? key,
    required this.deviceInfo,
  }) : super(key: key);

  @override
  State<WearableInfoWidget> createState() => _WearableInfoWidgetState();
}

class _WearableInfoWidgetState extends State<WearableInfoWidget> {
  HeartRateSensor? heartRateSensor;
  HeartRateVariabilitySensor? heartRateVariabilitySensor;

  @override
  void initState() {
    super.initState();
    // Note: Sensor management is now handled by the background service
    // No need to initialize sensors here
  }

  @override
  Widget build(BuildContext context) {
    // We no longer have access to the wearable icon path method
    // Using a Material icon instead

    return GroupedBox(
      title: widget.deviceInfo['name'] as String,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Use a placeholder icon since we can't access the actual wearable icon
          SizedBox(
            width: 80,
            height: 80,
            child: Icon(
              Icons.watch,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // We don't have direct access to the device features anymore
              // Show some basic information from the device info
              Text(
                "Device ID: ${widget.deviceInfo['id']}",
              ),
              const SizedBox(height: 10),
              Text(
                "Type: ${widget.deviceInfo['type'] ?? 'Unknown'}",
              ),
              const SizedBox(height: 20),
              // Heart rate information now comes from the controller
              // instead of directly from the device
              const Text(
                "Heart Rate: See status bar for real-time updates",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
