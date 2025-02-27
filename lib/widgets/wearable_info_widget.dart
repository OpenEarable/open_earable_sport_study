import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'grouped_box.dart';

class WearableInfoWidget extends StatefulWidget {
  final Wearable wearable;

  const WearableInfoWidget({
    Key? key,
    required this.wearable,
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
    // Search heart rate sensor
    if (widget.wearable is SensorManager) {
      for (var sensor in (widget.wearable as SensorManager).sensors) {
        if (sensor is HeartRateSensor) {
          heartRateSensor = sensor;
        }
        if (sensor is HeartRateVariabilitySensor) {
          heartRateVariabilitySensor = sensor;
        }
      }
    }

    // Enable heart rate sensor if needed
    if (heartRateSensor != null) {
      for (final relatedConfig in heartRateSensor!.relatedConfigurations) {
        if (relatedConfig is SensorFrequencyConfiguration) {
          relatedConfig.setMaximumFrequency();
        }
      }
    }

    // Enable heart rate variability sensor if needed
    if (heartRateVariabilitySensor != null) {
      for (final relatedConfig
          in heartRateVariabilitySensor!.relatedConfigurations) {
        if (relatedConfig is SensorFrequencyConfiguration) {
          relatedConfig.setMaximumFrequency();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wearableIconPath = widget.wearable.getWearableIconPath();

    return GroupedBox(
      title: widget.wearable.name,
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
            children: [
              if (widget.wearable is DeviceFirmwareVersion)
                FutureBuilder<String?>(
                  future: (widget.wearable as DeviceFirmwareVersion)
                      .readDeviceFirmwareVersion(),
                  builder: (context, snapshot) {
                    return SelectableText(
                      "Firmware: ${snapshot.data}",
                    );
                  },
                ),
              if (widget.wearable is DeviceHardwareVersion)
                FutureBuilder<String?>(
                  future: (widget.wearable as DeviceHardwareVersion)
                      .readDeviceHardwareVersion(),
                  builder: (context, snapshot) {
                    return SelectableText(
                      "Hardware: ${snapshot.data}",
                    );
                  },
                ),
              if (widget.wearable is BatteryLevelService)
                StreamBuilder(
                  stream: (widget.wearable as BatteryLevelService)
                      .batteryPercentageStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        "Battery:\t${snapshot.data}%",
                      );
                    } else {
                      return const Text(
                        "Battery:\t###",
                      );
                    }
                  },
                ),
              const SizedBox(height: 20),
              if (heartRateSensor != null)
                StreamBuilder(
                  stream: heartRateSensor!.sensorStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        "Heart Rate:\t${snapshot.data!.heartRateBpm} bpm",
                      );
                    } else {
                      return const Text(
                        "Heart Rate:\t###",
                      );
                    }
                  },
                ),
              if (heartRateSensor == null)
                const Text(
                  "Heart Rate:\tNot available",
                ),
              if (heartRateVariabilitySensor != null)
                const SizedBox(height: 20),
              if (heartRateVariabilitySensor != null)
                const Text(
                  "Heart Rate Variability",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (heartRateVariabilitySensor != null)
                StreamBuilder(
                  stream: heartRateVariabilitySensor!.sensorStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                            heartRateVariabilitySensor!.axisCount, (index) {
                          return Text(
                            '${heartRateVariabilitySensor!.axisNames[index]}:\t ${snapshot.data!.values[index].toStringAsFixed(2)}',
                          );
                        }),
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                            heartRateVariabilitySensor!.axisCount, (index) {
                          return Text(
                            '${heartRateVariabilitySensor!.axisNames[index]}:\t ###',
                          );
                        }),
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
