import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ditto_live/ditto_live.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';


final logger = Logger();

// Singleton usage: DittoService.instance
class DittoService {
  static final DittoService instance = DittoService._internal();
  Ditto? _ditto;
  StoreObserver? _observer;
  List<Map<String, dynamic>> _files = [];

  DittoService._internal();
  Ditto? get ditto => _ditto;

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

    _observer = _ditto!.store.registerObserver(
      "SELECT name, createdAt, attachment, selfieAttachment FROM files ORDER BY createdAt DESC",
      onChange: (resultSet) {
        _files = resultSet.items
            .map((item) => Map<String, dynamic>.from(item.value))
            .toList();

        onFilesUpdated();
      },
    );
    return _ditto!;
  }

  // UI can call this
  List<Map<String, dynamic>> getFiles() => _files;

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

  Future<void> addImageFromBytes(Uint8List imageBytes, {String? fileName}) async {
  if (_ditto == null) {
    print('❌ Ditto ist null in addImageFromBytes');
    return;
  }

  try {
    print('📸 Saving image: ${imageBytes.length} bytes');

    // 1. Attachment erzeugen
    final attachment = await _ditto!.store.newAttachment(imageBytes);
    print('✅ Attachment created. id=${attachment.id}, len=${attachment.len}');

    // 2. Dokument vorbereiten
    final newDocument = {
      "name": fileName ?? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      "createdAt": DateTime.now().millisecondsSinceEpoch,
      "attachment": attachment,
      "author": localPeerId,
      "size": imageBytes.length,
    };

    // 3. DQL-Insert (mit COLLECTION + ATTACHMENT)
    await _ditto!.store.execute(
      '''
      INSERT INTO COLLECTION files (attachment ATTACHMENT)
      VALUES (:newDocument)
      ''',
      arguments: {
        "newDocument": newDocument,
      },
    );

    print('✅ Document saved to Ditto');

  } catch (e) {
    print('❌ Error saving image: $e');
  }
}

Future<void> addDualImageFromBytes(
  Uint8List mainBytes,
  Uint8List selfieBytes, {
  String? fileName,
}) async {
  if (_ditto == null) {
    print('❌ Ditto ist null in addDualImageFromBytes');
    return;
  }

  try {
    print('📸 Saving dual image: main=${mainBytes.length}, selfie=${selfieBytes.length} bytes');

    final mainAttachment = await _ditto!.store.newAttachment(mainBytes);
    final selfieAttachment = await _ditto!.store.newAttachment(selfieBytes);

    print('✅ Attachments created: main=${mainAttachment.id}, selfie=${selfieAttachment.id}');

    final newDocument = {
      "name": fileName ??
          'peerreal_${DateTime.now().millisecondsSinceEpoch}.jpg',
      "createdAt": DateTime.now().millisecondsSinceEpoch,
      "attachment": mainAttachment,        // Hauptbild
      "selfieAttachment": selfieAttachment, // Selfie
      "author": localPeerId,
      "mainSize": mainBytes.length,
      "selfieSize": selfieBytes.length,
    };

    await _ditto!.store.execute(
      '''
      INSERT INTO COLLECTION files (attachment ATTACHMENT, selfieAttachment ATTACHMENT)
      VALUES (:newDocument)
      ''',
      arguments: {
        "newDocument": newDocument,
      },
    );

    print('✅ Dual-image document saved to Ditto');
  } catch (e) {
    print('❌ Error saving dual image: $e');
  }
}


Future<Uint8List?> _loadAttachmentFromToken(
    Map<String, dynamic>? attachmentToken) async {
  try {
    if (_ditto == null) {
      print('❌ Ditto is null in _loadAttachmentFromToken');
      return null;
    }

    if (attachmentToken == null) {
      print('ℹ️ No attachment token provided');
      return null;
    }

    print('🔑 Attachment token: $attachmentToken');

    final completer = Completer<Uint8List?>();

    print('🔄 Starting attachment fetch...');
    final fetcher = _ditto!.store.fetchAttachment(
      attachmentToken,
      (event) async {
        if (event is AttachmentFetchEventCompleted) {
          print('✅ Attachment fetch completed, loading data...');
          try {
            final data = await event.attachment.data;
            print('📦 Attachment data loaded: ${data.length} bytes');
            if (!completer.isCompleted) {
              completer.complete(data);
            }
          } catch (e) {
            print('❌ Error getting attachment data: $e');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        } else if (event is AttachmentFetchEventProgress) {
          print(
              '📥 Download progress: ${event.downloadedBytes}/${event.totalBytes} bytes');
        } else if (event is AttachmentFetchEventDeleted) {
          print('❌ Attachment was deleted');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        } else {
          print('ℹ️ Other fetch event: $event');
        }
      },
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏰ Attachment fetch timeout');
        fetcher.stop();
        return null;
      },
    );

    print(result != null
        ? '🎉 Successfully loaded image'
        : '💥 Failed to load image');
    return result;
  } catch (e) {
    print('❌ Error in _loadAttachmentFromToken: $e');
    return null;
  }
}

// Hauptbild
Future<Uint8List?> getAttachmentData(Map<String, dynamic> doc) async {
  return _loadAttachmentFromToken(doc['attachment']);
}

// Selfie-Bild
Future<Uint8List?> getSelfieAttachmentData(
    Map<String, dynamic> doc) async {
  return _loadAttachmentFromToken(doc['selfieAttachment']);
}

  void dispose() {
    _observer?.cancel();
    _ditto?.stopSync();
    _ditto?.close();
  }
}


