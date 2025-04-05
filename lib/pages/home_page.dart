import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recording_controller.dart';
import '../controllers/settings_controller.dart';

import '../widgets/action_app_bar.dart';
import '../widgets/wearable_info_list_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showEditParticipantIdDialog(BuildContext context, SettingsController settingsController) {
    final TextEditingController textController = TextEditingController(text: settingsController.participantId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Participant ID'),
          content: TextField(
            controller: textController,
            autofocus: true,
            onSubmitted: (value) {
              settingsController.setParticipantId(value);
              Navigator.of(context).pop();
            },
            decoration: const InputDecoration(
              hintText: 'Enter Participant ID',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                settingsController.setParticipantId(textController.text);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Provider.of<SettingsController>(context);
    final recordingController = Provider.of<RecordingController>(context);

    return Scaffold(
      appBar: ActionAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      settingsController.participantId.isEmpty
                        ? 'Participant ID: [Not set]'
                        : 'Participant ID: ${settingsController.participantId}',
                      style: TextStyle(
                        fontSize: 16,
                        color: settingsController.participantId.isEmpty ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: settingsController.participantId.isEmpty ? Colors.red : null),
                    onPressed: () => _showEditParticipantIdDialog(context, settingsController),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: settingsController.participantId.isEmpty
                      ? null
                      : recordingController.start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    fixedSize: const Size.fromHeight(60),
                  ),
                  child: const Text('Start Recording'),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const WearableInfoListWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
