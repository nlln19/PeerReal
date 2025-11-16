import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:peer_real/services/ditto_service.dart';

class ImageGridItem extends StatefulWidget {
  final Map<String, dynamic> doc;

  const ImageGridItem({
    super.key,
    required this.doc,
  });

  @override
  State<ImageGridItem> createState() => _ImageGridItemState();
}

class _ImageGridItemState extends State<ImageGridItem> {
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    print('🖼️ Initializing ImageGridItem for: ${widget.doc['name']}');
    _loadImage();
  }

  Future<void> _loadImage() async {
    print('🔄 Loading image for: ${widget.doc['name']}');
    
    try {
      final imageData = await DittoService.instance.getAttachmentData(widget.doc);
      print('📊 Image data result: ${imageData?.length} bytes');
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
        });
      }
    } catch (e) {
      print('❌ Error in _loadImage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building ImageGridItem with data: ${_imageData?.length} bytes');
    
    return Container(
      color: _imageData != null ? Colors.green : Colors.red, // Farbige Indikatoren
      child: _imageData != null && _imageData!.isNotEmpty
          ? Image.memory(
              _imageData!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Image decode error: $error');
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white),
                      Text(
                        'Decode error',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white),
                  Text(
                    'No Image',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
    );
  }
}
