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

//   @override
//   Widget build(BuildContext context) {
//     final id = doc["_id"] ?? "No ID";
//     final name = doc["name"] ?? "Unnamed file";
//     final attachment = doc["attachment"];

//     return ListTile(
//       title: Text(name),
//       subtitle: Text("ID: $id\nAttachment Token: $attachment"),
//     );
//   }
// }

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
          title: Text(doc["name"] ?? "Unnamed"),
          leading: Image.memory(snap.data!, width: 56, height: 56, fit: BoxFit.cover),
          
        );
      },
    );
  }
}


