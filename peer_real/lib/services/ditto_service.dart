import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // <-- FIX 1
import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

final logger = Logger();

class DittoService {
  Ditto? _ditto;
  StoreObserver? _observer;
  List<Map<String, dynamic>> _files = [];

  final String localPeerId = const Uuid().v4();

  // onFilesUpdated = callback to update UI
  Future<Ditto> init(VoidCallback onFilesUpdated) async {
    await Ditto.init();

    final identity = OnlinePlaygroundIdentity(
      appID: dotenv.env['DITTO_APP_ID']!,
      token: dotenv.env['DITTO_PLAYGROUND_TOKEN']!,
      enableDittoCloudSync: false,
      customAuthUrl: dotenv.env['DITTO_AUTH_URL'],
    );

    _ditto = await Ditto.open(identity: identity);

    _ditto!.updateTransportConfig((config) {
      config.setAllPeerToPeerEnabled(true);
      config.connect.webSocketUrls.add(dotenv.env['DITTO_WEBSOCKET_URL']!);
    });

    await _ditto!.store.execute("ALTER SYSTEM SET DQL_STRICT_MODE = false");
    _ditto!.startSync();

    // FIX 2 — store items manually
    _observer = _ditto!.store.registerObserver(
      "SELECT fileId, name, createdAt, attachment FROM files ORDER BY createdAt DESC",
      onChange: (resultSet) {
        _files = resultSet.items
            .map((item) => Map<String, dynamic>.from(item.value))
            .toList();

        onFilesUpdated(); // tell UI to refresh
      },
    );

    return _ditto!;
  }

  // UI can call this
  List<Map<String, dynamic>> getFiles() => _files;

  Future<void> addSampleImage() async {
    if (_ditto == null) return;

    final bytes = await rootBundle.load('assets/Ameise.jpg');
    final data = bytes.buffer.asUint8List();

    final token = await _ditto!.store.newAttachment(data);

    final fileId = const Uuid().v4();

    await _ditto!.store.execute(
      "INSERT INTO COLLECTION files (attachment ATTACHMENT) VALUES (:doc)",
      arguments: {
        "doc": {
          "fileID": fileId,
          "name": "Ameise.jpg",
          "createdAt": DateTime.now().millisecondsSinceEpoch,
          "attachment": token,
          "author": localPeerId,
        },
      },
    );
  }

  Future<Uint8List?> getImageBytes(Map<String, dynamic> doc) async {
    final token = doc["attachment"];
    if (token == null) return null;

    final completer = Completer<Uint8List>();

    _ditto!.store.fetchAttachment(token, (event) {
      if (event is AttachmentFetchEventCompleted) {
        completer.complete(event.attachment.data);
      }
    });

    return completer.future;
  }

  /// ---------- COMMENTS API ----------

  Future<void> addComment({
    required String fileId,
    required String text,
    required String author,
  }) async {
    if (_ditto == null) {
      debugPrint("addComment called but _ditto is null");
      return;
    }

    debugPrint("DittoService.addComment(fileId=$fileId, text='$text')");

    try {
      await _ditto!.store.execute(
        "INSERT INTO COLLECTION comments (doc) VALUES (:doc)",
        arguments: {
          "doc": {
            "fileId": fileId,
            "text": text,
            "author": author,
            "createdAt": DateTime.now().millisecondsSinceEpoch,
          },
        },
      );
      debugPrint("DittoService.addComment finished");
    } catch (e, st) {
      debugPrint("ERROR in DittoService.addComment: $e\n$st");
    }
  }

  /// Register an observer for comments of a single file.
  /// We observe all comments and filter by fileId in Dart
  /// (avoids needing query arguments support).
  StoreObserver registerCommentsObserver(
    String fileId,
    void Function(List<Map<String, dynamic>> comments) onUpdate,
  ) {
    if (_ditto == null) {
      throw StateError(
        "DittoService not initialized before observing comments",
      );
    }

    return _ditto!.store.registerObserver(
      "SELECT fileId, text, author, createdAt FROM comments ORDER BY createdAt ASC",
      onChange: (resultSet) {
        final allComments = resultSet.items
            .map((item) => Map<String, dynamic>.from(item.value))
            .toList();

        final filtered = allComments
            .where((c) => c["fileId"] == fileId)
            .toList();

        onUpdate(filtered);
      },
    );
  }

  void dispose() {
    _observer?.cancel();
    _ditto?.stopSync();
    _ditto?.close();
  }
}
