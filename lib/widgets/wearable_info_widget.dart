import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'grouped_box.dart';

class WearableInfoWidget extends StatefulWidget {
  final Map<String, dynamic> wearable;

  const WearableInfoWidget({
    Key? key,
    required this.wearable,
  }) : super(key: key);

  @override
  State<WearableInfoWidget> createState() => _WearableInfoWidgetState();
}

class _WearableInfoWidgetState extends State<WearableInfoWidget> {
  @override
  void initState() {
    super.initState();
    // No-op: advanced sensor features are not available for map-based devices.
  }

  @override
  Widget build(BuildContext context) {
    final wearableIconPath = widget.wearable['iconPath'];

    return GroupedBox(
      title: widget.wearable['name'] ?? '',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (wearableIconPath != null)
            SizedBox(
              width: 80,
              height: 80,
              child: SvgPicture.asset(
                wearableIconPath,
              ),
            ),
          if (wearableIconPath != null) const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Battery: N/A"),
              const SizedBox(height: 20),
              Text("Heart Rate: N/A"),
              const SizedBox(height: 20),
              Text("Heart Rate Variability: N/A"),
            ],
          ),
        ],
      ),
    );
  }
}
