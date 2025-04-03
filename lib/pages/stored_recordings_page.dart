import 'package:flutter/material.dart';
import 'package:open_earable_flutter_edge_ml_connection/open_earable_flutter_edge_ml_connection.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class StoredRecordingsPage extends StatelessWidget {
  const StoredRecordingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stored Recordings"),
        leading: const BackButton(),
      ),
      body: FutureBuilder<List<String>>(
        future: CsvOpenEarableEdgeMLConnection.listCsvFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recording found.'));
          } else {
            final files = snapshot.data!;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final filePath = files[index];
                final fileName = filePath.split('/').last;
                return ListTile(
                  title: Text(fileName),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Choose an action'),
                          content: Text(
                            'What do you want to do with $fileName?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await Share.shareXFiles([XFile(filePath)]);
                              },
                              child: const Text('Share'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await OpenFile.open(filePath);
                              },
                              child: const Text('Open'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
