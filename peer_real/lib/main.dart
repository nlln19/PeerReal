import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ditto_live/ditto_live.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

var logger = Logger();

final String localPeerId = const Uuid().v4(); // unique per app install


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Returns an instance of the binding that implements [WidgetsBinding]. If no binding has yet been initialized, the [WidgetsFlutterBinding] class is used to create and initialize one. You only need to call this method if you need the binding to be initialized before calling [runApp].
  await dotenv.load(fileName: ".env"); //Ditto Setup vom .env werden geladen
  runApp(const MaterialApp(home: PeerRealDemo()));
}

class PeerRealDemo extends StatefulWidget {  //State sind Informationen auf den Widgets -> state of the widget is the data of the objects that its properties (parameters) are sustaining at the time of its creation
  const PeerRealDemo({super.key}); //Stateless: The widgets whose state can not be altered once they are built. Statefull: Can Alter.
  @override
  State<PeerRealDemo> createState() => _PeerRealDemoState();
}

class _PeerRealDemoState extends State<PeerRealDemo> {
  Ditto? _ditto;
  final appID =
      dotenv.env['DITTO_APP_ID'] ?? (throw Exception("env not found"));
  final token = dotenv.env['DITTO_PLAYGROUND_TOKEN'] ??
      (throw Exception("env not found"));
  final authUrl = dotenv.env['DITTO_AUTH_URL'];
  final websocketUrl =
      dotenv.env['DITTO_WEBSOCKET_URL'] ?? (throw Exception("env not found"));

  StoreObserver? _observer;
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _initDitto();
    logger.d("works 49");
  }

  Future<void> _initDitto() async {
 
    // Request permissions on mobile
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await [
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
      ].request();
    }

    await Ditto.init();
    
    final identity = OnlinePlaygroundIdentity(
      appID: appID,
      token: token,
      enableDittoCloudSync: false,
      customAuthUrl: authUrl);

    final ditto = await Ditto.open(identity: identity);
    
    ditto.updateTransportConfig((config) {
      // Note: this will not enable peer-to-peer sync on the web platform
      config.setAllPeerToPeerEnabled(true);
      config.connect.webSocketUrls.add(websocketUrl);
      logger.d("works 78");
    });

    await ditto.store.execute("ALTER SYSTEM SET DQL_STRICT_MODE = false");
    
    ditto.startSync();

    if(mounted){
      setState(() {
        _ditto = ditto;
      });
      logger.d("works 89");
    }

    //AB DO MUSS MEH KORRIGIERE

    // Observe collection
    final observer = ditto.store.registerObserver(
    "SELECT name, createdAt, attachment FROM files ORDER BY createdAt DESC",
    onChange: (res) {
      setState(() {
        _files = res.items.map((r) => Map<String, dynamic>.from(r.value)).toList();
        logger.d("works 100");
      });
    },  
  );



    setState(() {
      _ditto = ditto;
      _observer = observer;
    });
  }
  
  /// Inserts a hard-coded image as attachment and document
  // Future<void> addSampleImage() async {
    
  //   if (_ditto == null) return;
  //   // Load image bytes (assets/Ameise.jpg)
  //   final attachment = await _ditto!.store.newAttachment('assets/Ameise.jpg',
  //   AttachmentMetadata({"name": "Ameise.jpg"}),
  //   );

  //   final document = {
  //     "_id": "123",
  //     "my_attachment": attachment,
  //   };

  //   final query = "INSERT INTO COLLECTION files (my_attachment ATTACHMENT) VALUES (:document)";

  //   await _ditto!.store.execute(query); 
  //   debugPrint("Inserted Ameise.jpg with attachment token");
  // }
  Future<void> addSampleImage() async {
  if (_ditto == null) return;

  // Load image as bytes (you can later replace this with a picker)
  final bytes = await rootBundle.load('assets/Ameise.jpg');
  final data = bytes.buffer.asUint8List();

  // Create the attachment token for this image
  final token = await _ditto!.store.newAttachment(data);

  // Insert the metadata document
  await _ditto!.store.execute(
    "INSERT INTO COLLECTION files (attachment ATTACHMENT) VALUES (:doc)",
    arguments: {
      "doc": {
        "name": "Ameise.jpg",
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "attachment": token,
        "author": localPeerId, // identify which peer sent it
      },
    },
  );
  logger.d("works 154");
}


  Future<ImageProvider?> _getImage(Map<String, dynamic> doc) async {
  final token = doc["attachment"] as Map<String, dynamic>?;
  if (token == null) return null;

  // This Completer will complete when the attachment finishes downloading.
  final completer = Completer<Uint8List>();

  // Begin fetching the attachment using the token.
  _ditto!.store.fetchAttachment(token, (event) {
    if (event is AttachmentFetchEventCompleted) {
      // When the attachment is completely downloaded, complete the future.
      completer.complete(event.attachment.data);
    } else if (event is AttachmentFetchEventProgress) {
      // Progress update (optional)
      debugPrint(
        "Downloading attachment: ${event.downloadedBytes} / ${event.totalBytes} bytes",
      );
    } else if (event is AttachmentFetchEventDeleted) {
      // The attachment was deleted before it could be fetched.
      completer.completeError(Exception("Attachment deleted"));
    }
    logger.d("works 179");
  });

  try {
    // Wait until the attachment is fully fetched.
    final bytes = await completer.future;
    return MemoryImage(bytes); // Use bytes to display image in Flutter
  } catch (e) {
    debugPrint("Failed to fetch attachment: $e");
    return null;
  }
}




  @override
  Widget build(BuildContext context) {
    final ditto = _ditto;
    if (ditto == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("PeerReal"), backgroundColor: Color.fromRGBO(61, 61, 129, 1),),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: addSampleImage,
        child: const Icon(Icons.cloud_upload),
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, i) {
          final doc = _files[i];
          return FutureBuilder<ImageProvider?>(
            future: _getImage(doc),
            builder: (context, snap) {
              if (!snap.hasData) {
                return ListTile(
                  title: Text(doc["name"] ?? "Unnamed"),
                  subtitle: const Text("Loading image..."),
                );
              }
              return ListTile(
                leading: Image(image: snap.data!, width: 56, height: 56),
                title: Text(doc["name"] ?? "Unnamed"),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _observer?.cancel();
    _ditto?.stopSync();
    _ditto?.close();
    super.dispose();
  }
}
