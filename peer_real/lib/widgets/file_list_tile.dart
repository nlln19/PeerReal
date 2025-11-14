import 'package:flutter/material.dart';
import '../services/ditto_service.dart';

class FileListTile extends StatelessWidget {
  final Map<String, dynamic> doc;
  final DittoService dittoService;

  const FileListTile({
    super.key,
    required this.doc,
    required this.dittoService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: dittoService.getImageBytes(doc),
      builder: (context, snap) {
        if (!snap.hasData) {
          return ListTile(
            title: Text(doc["name"] ?? "Unnamed"),
            subtitle: const Text("Loading image..."),
          );
        }

        return ListTile(
          leading: Image.memory(snap.data!, width: 56, height: 56),
          title: Text(doc["name"] ?? "Unnamed"),
        );
      },
    );
  }
}
