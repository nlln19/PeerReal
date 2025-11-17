import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:PeerReal/services/ditto_service.dart';

class PeerRealPostCard extends StatefulWidget {
  final Map<String, dynamic> doc;

  const PeerRealPostCard({
    super.key,
    required this.doc,
  });

  @override
  State<PeerRealPostCard> createState() => _PeerRealPostCardState();
}

class _PeerRealPostCardState extends State<PeerRealPostCard> {
  Uint8List? _imageData;
  Uint8List? _selfieData;


  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
  try {
    final main = await DittoService.instance.getAttachmentData(widget.doc);
    final selfie = await DittoService.instance.getSelfieAttachmentData(widget.doc);

    if (!mounted) return;
    setState(() {
      _imageData = main;
      _selfieData = selfie;
    });
  } catch (e) {
    print('❌ Error loading images in PostItem: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    final createdAtMs = widget.doc['createdAt'] as int?;
    final createdAt = createdAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAtMs).toLocal()
        : null;

    final timeLabel = createdAt != null
        ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}"
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopfzeile: „You • 21:05“
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, size: 18, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '• $timeLabel',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Bildkarte im BeReal-Style
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
                maxHeight: 560,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    color: Colors.black26,
                    child: _imageData == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              // Hauptbild
                              Image.memory(
                                _imageData!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Main image decode error: $error');
                                  return const Center(
                                    child:
                                        Icon(Icons.broken_image, color: Colors.white70),
                                  );
                                },
                              ),

                              // Selfie oben rechts (falls vorhanden)
                              if (_selfieData != null)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 90,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Image.memory(
                                        _selfieData!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Selfie decode error: $error');
                                          return const ColoredBox(
                                            color: Colors.black54,
                                            child: Icon(Icons.broken_image,
                                                color: Colors.white70, size: 20),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
