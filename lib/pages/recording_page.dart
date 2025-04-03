import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../controllers/connected_device_controller.dart';
import '../controllers/recording_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/wearable_info_list_widget.dart';
import 'recording_ended_page.dart';

class RecordingPage extends StatelessWidget {
  const RecordingPage({Key? key}) : super(key: key);

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    final recordingController = Provider.of<RecordingController>(context);
    final settingsController = Provider.of<SettingsController>(context);
    final connectedDeviceController =
        Provider.of<ConnectedDeviceController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Participant ID: ${settingsController.participantId}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  _formatDuration(recordingController.recordingDuration),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                StreamBuilder(
                  stream: connectedDeviceController.heartRateStream,
                  builder: (_, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        "Heart Rate: ${snapshot.data}bpm",
                        style: const TextStyle(fontSize: 16),
                      );
                    } else {
                      return const Text(
                        "Heart Rate: N/A",
                        style: TextStyle(fontSize: 16),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                SlideAction(
                  height: 52.0,
                  borderRadius: 52,
                  sliderButtonIconSize: 40.0,
                  sliderButtonIconPadding: 3,
                  text: "Slide to Stop",
                  outerColor: const Color(0xFFDA5252),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  onSubmit: () async {
                    recordingController.stop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecordingEndedPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const WearableInfoListWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
