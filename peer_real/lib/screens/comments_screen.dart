import 'package:flutter/material.dart';
import 'package:ditto_live/ditto_live.dart';

import '../services/ditto_service.dart';

class CommentsScreen extends StatefulWidget {
  final Map<String, dynamic> fileDoc;
  final DittoService dittoService;

  const CommentsScreen({
    super.key,
    required this.fileDoc,
    required this.dittoService,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late final String fileId;
  late final TextEditingController _controller;
  List<Map<String, dynamic>> _comments = [];
  StoreObserver? _observer;

  @override
  void initState() {
    super.initState();
    fileId = widget.fileDoc["_id"];
    _controller = TextEditingController();

    // Watch comments for this particular file
    _observer = widget.dittoService.registerCommentsObserver(fileId, (
      comments,
    ) {
      setState(() {
        _comments = comments;
      });
    });
  }

  @override
  void dispose() {
    _observer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.add({
        "fileId": fileId,
        "text": text,
        "author": "local",
        "createdAt": DateTime.now().millisecondsSinceEpoch,
      });
    });

    _controller.clear();
  }

  /*debugPrint("sendComment called with text='$text'");

    if (text.isEmpty) {
      debugPrint("text is empty, aborting");
      return;
    }

    try {
      debugPrint("calling addComment with fileId=$fileId");
      await widget.dittoService.addComment(
        fileId: fileId,
        text: text,
        author: widget.dittoService.localPeerId,
      );
      debugPrint("addComment completed");

      _controller.clear();
    } catch (e, st) {
      debugPrint("ERROR in _sendComment: $e\n$st");
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final fileName = widget.fileDoc["name"] ?? "File";

    return Scaffold(
      appBar: AppBar(title: Text("Comments on $fileName")),
      body: Column(
        children: [
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Text(
                      "No comments yet. Be the first!",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, i) {
                      final c = _comments[i];
                      final text = c["text"] ?? "";
                      final author = c["author"] ?? "unknown";
                      final ts = c["createdAt"] as int?;
                      final date = ts != null
                          ? DateTime.fromMillisecondsSinceEpoch(ts)
                          : null;

                      return ListTile(
                        title: Text(text),
                        subtitle: Text(
                          "by $author"
                          "${date != null ? " · ${date.toLocal()}" : ""}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      debugPrint("onSubmitted called");
                      _sendComment();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    debugPrint("Send button pressed");
                    _sendComment();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
