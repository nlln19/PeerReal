import 'dart:async';

import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../services/logger_service.dart';

class DittoService {
  static final DittoService instance = DittoService._internal();
  Ditto? _ditto;

  DittoService._internal();

  Ditto get ditto {
    final d = _ditto;
    if (d == null) {
      throw StateError('DittoService not initialized. Call init() first.');
    }
    return d;
  }

  final String localPeerId = const Uuid().v4();

  Future<Ditto> init() async {
    if (_ditto != null) return _ditto!;

    await Ditto.init();

    final appId        = dotenv.env['DITTO_APP_ID']!;
    final token        = dotenv.env['DITTO_PLAYGROUND_TOKEN']!;
    final authUrl      = dotenv.env['DITTO_AUTH_URL']!;
    final websocketUrl = dotenv.env['DITTO_WEBSOCKET_URL']!;

    final identity = OnlinePlaygroundIdentity(
      appID: appId,
      token: token,
      customAuthUrl: authUrl,
      enableDittoCloudSync: false,
    );

    final ditto = await Ditto.open(identity:identity);
    logger.i('✅ Ditto opened with appId=$appId');

    ditto.updateTransportConfig((config) {
      // Cloud-Verbindung
      config.connect.webSocketUrls.add(websocketUrl);

      // P2P nur auf Mobile
      if (!kIsWeb) {
        config.setAllPeerToPeerEnabled(true);
      }
    });

    await ditto.store.execute(
      "ALTER SYSTEM SET DQL_STRICT_MODE = false",
    );

    ditto.startSync();
    logger.i('🚀 Ditto sync started');

    _ditto = ditto;
    return ditto;
  }

  Future<void> addImageFromBytes(
    Uint8List imageBytes, {
    String? fileName,
  }) async {
    final d = _ditto;
    if (d == null) {
      logger.e('❌ Ditto is null in addImageFromBytes');
      return;
    }

    try {
      logger.i('📸 Saving image: ${imageBytes.length} bytes');

      final attachment = await d.store.newAttachment(imageBytes);
      logger.i('✅ Attachment created. id=${attachment.id}, len=${attachment.len}');

      final newDocument = {
        "name": fileName ??
            'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "attachment": attachment,
        "author": localPeerId,
        "size": imageBytes.length,
      };

      await d.store.execute(
        '''
        INSERT INTO COLLECTION files (attachment ATTACHMENT)
        VALUES (:newDocument)
        ''',
        arguments: {"newDocument": newDocument},
      );

      logger.i('✅ Document saved to Ditto');
    } catch (e) {
      logger.e('❌ Error saving image: $e');
    }
  }

  Future<void> addDualImageFromBytes(
    Uint8List mainBytes,
    Uint8List selfieBytes, {
    String? fileName,
  }) async {
    final d = _ditto;
    if (d == null) {
      logger.e('❌ Ditto ist null in addDualImageFromBytes');
      return;
    }

    try {
      logger.i(
          '📸 Saving dual image: main=${mainBytes.length}, selfie=${selfieBytes.length} bytes');

      final mainAttachment = await d.store.newAttachment(mainBytes);
      final selfieAttachment = await d.store.newAttachment(selfieBytes);

      logger.i(
          '✅ Attachments created: main=${mainAttachment.id}, selfie=${selfieAttachment.id}');

      final newDocument = {
        "name": fileName ??
            'peerreal_${DateTime.now().millisecondsSinceEpoch}.jpg',
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "attachment": mainAttachment,
        "selfieAttachment": selfieAttachment,
        "author": localPeerId,
        "mainSize": mainBytes.length,
        "selfieSize": selfieBytes.length,
      };

      await d.store.execute(
        '''
        INSERT INTO COLLECTION files (attachment ATTACHMENT, selfieAttachment ATTACHMENT)
        VALUES (:newDocument)
        ''',
        arguments: {"newDocument": newDocument},
      );

      logger.i('✅ Dual Image saved to Ditto');
    } catch (e) {
      logger.e('❌ Error saving dual image: $e');
    }
  }

  Future<Uint8List?> _loadAttachmentFromToken(
      Map<String, dynamic>? attachmentToken) async {
    try {
      final d = _ditto;
      if (d == null) {
        logger.e('❌ Ditto is null in _loadAttachmentFromToken');
        return null;
      }

      if (attachmentToken == null) {
        logger.w('ℹ️ No attachment token provided');
        return null;
      }

      logger.i('🔑 Attachment token: $attachmentToken');

      final completer = Completer<Uint8List?>();

      logger.i('🔄 Starting attachment fetch...');
      final fetcher = d.store.fetchAttachment(
        attachmentToken,
        (event) async {
          if (event is AttachmentFetchEventCompleted) {
            logger.i('✅ Attachment fetch completed, loading data...');
            try {
              final data = await event.attachment.data;
              logger.i('📦 Attachment data loaded: ${data.length} bytes');
              if (!completer.isCompleted) {
                completer.complete(data);
              }
            } catch (e) {
              logger.e('❌ Error getting attachment data: $e');
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            }
          } else if (event is AttachmentFetchEventProgress) {
            logger.i('📥 Download progress: ${event.downloadedBytes}/${event.totalBytes} bytes');
          } else if (event is AttachmentFetchEventDeleted) {
            logger.e('❌ Attachment was deleted');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          } else {
            logger.i('ℹ️ Other fetch event: $event');
          }
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.w('⏰ Attachment fetch timeout');
          fetcher.stop();
          return null;
        },
      );

      logger.i(result != null
          ? '🎉 Successfully loaded image'
          : '💥 Failed to load image');
      return result;
    } catch (e) {
      logger.e('❌ Error in _loadAttachmentFromToken: $e');
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
    _ditto?.stopSync();
    _ditto?.close();
    _ditto = null;
  }
}
