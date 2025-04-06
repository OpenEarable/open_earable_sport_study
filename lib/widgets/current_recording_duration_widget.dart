import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/recording_controller.dart';

class CurrentRecordingDurationWidget extends StatelessWidget {
  const CurrentRecordingDurationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime? recordingStart = context.watch<RecordingController>().recordingStart;

    if (recordingStart == null) {
      return const Text(
        "N/A",
        style: TextStyle(fontSize: 16),
      );
    }
    return _InnerCurrentRecordingDurationWidget(
      recordingStart: recordingStart,
    );
  }
}

class _InnerCurrentRecordingDurationWidget extends StatefulWidget {
  final DateTime recordingStart;

  const _InnerCurrentRecordingDurationWidget({required this.recordingStart, Key? key}) : super(key: key);

  @override
  State<_InnerCurrentRecordingDurationWidget> createState() => __InnerCurrentRecordingDurationWidgetState();
}

class __InnerCurrentRecordingDurationWidgetState extends State<_InnerCurrentRecordingDurationWidget> {
  Timer? _timer;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.recordingStart);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = DateTime.now().difference(widget.recordingStart);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_duration),
      style: const TextStyle(fontSize: 16),
    );
  }
}
