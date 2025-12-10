import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:PeerReal/services/ditto_service.dart';
import '../services/logger_service.dart';

class ReactionsRow extends StatefulWidget {
  final String fileId;

  const ReactionsRow({super.key, required this.fileId});

  @override
  State<ReactionsRow> createState() => _ReactionsRowState();
}

class _ReactionsRowState extends State<ReactionsRow> {
  late Future<Map<String, int>> _futureCounts;

  @override
  void initState() {
    super.initState();
    _futureCounts = DittoService.instance.getReactionCountsForFile(widget.fileId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _futureCounts,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final counts = snapshot.data!;
        if (counts.isEmpty) {
          return const SizedBox.shrink();
        }

        // Idee: wir haben Emojis als Keys und ggf. 'selfie'
        final emojiOrder = ['💕', '😂', '😮'];
        final widgets = <Widget>[];

        for (final emoji in emojiOrder) {
          final count = counts[emoji] ?? 0;
          if (count > 0) {
            widgets.add(_ReactionPill(label: emoji, count: count));
          }
        }

        final selfieCount = counts['selfie'] ?? 0;
        if (selfieCount > 0) {
          widgets.add(_ReactionPill(
            label: '🤳',
            count: selfieCount,
          ));
        }

        if (widgets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 4.0),
          child: Row(
            children: widgets,
          ),
        );
      },
    );
  }
}

class _ReactionPill extends StatelessWidget {
  final String label;
  final int count;

  const _ReactionPill({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
