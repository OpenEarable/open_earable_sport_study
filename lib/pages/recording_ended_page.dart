import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/recording_controller.dart';

class RecordingEndedPage extends StatelessWidget {
  const RecordingEndedPage({Key? key}) : super(key: key);

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    final recordingController = Provider.of<RecordingController>(context);
    final lastRecording = recordingController.lastRecording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording ended'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: lastRecording != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Participant ID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: lastRecording.participantId),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Duration: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: _formatDuration(lastRecording.duration)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Start Heart Rate: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: lastRecording.startHeartRate != null ? '${lastRecording.startHeartRate}bpm' : 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Exercise Heart Rate: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: lastRecording.exerciseHeartRate != null ? '${lastRecording.exerciseHeartRate}bpm' : 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: Text('No recording data available.')),
    );
  }
}
