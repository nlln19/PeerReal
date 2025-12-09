import 'package:ditto_live/ditto_live.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/dql_builder_service.dart';
import '../services/ditto_service.dart';
import '../services/permission_service.dart';
import '../screens/camera_screen.dart';
import '../widgets/peer_real_post_card.dart';
import '../screens/profile_screen.dart';
import '../screens/friends_screen.dart';
import '../services/logger_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Ditto? _ditto;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await PermissionService.requestP2PPermissions();
    final ditto = await DittoService.instance.init();
    if (!mounted) return;
    setState(() {
      _ditto = ditto;
    });
  }

  Future<void> _openCamera() async {
    logger.i('📸 Opening Camera Screen');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result == null) return;

    // main + selfie
    if (result is Map &&
        result['main'] is Uint8List &&
        result['selfie'] is Uint8List) {
      final mainBytes = result['main'] as Uint8List;
      final selfieBytes = result['selfie'] as Uint8List;
      await DittoService.instance.addDualImageFromBytes(
        mainBytes,
        selfieBytes,
      );
    }
    // Fallback: altes Single-Bild
    else if (result is Uint8List) {
      await DittoService.instance.addImageFromBytes(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_ditto == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PeerReal.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              );
            },
          ),
        ],
      ),

      // Kamera-Button unten
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: _openCamera,
        child: const Icon(Icons.camera_alt),
      ),

      // Bottom-Bar
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0C0C15),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Feed',
                selected: true,
                onTap: () {
                  logger.i('🏠 Home tapped');
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
              const SizedBox(width: 40),
              _BottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: false,
                onTap: () {
                  logger.i('👤 Profile tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: DqlBuilderService(
        ditto: _ditto!,
        query: "SELECT * FROM reals ORDER BY createdAt DESC",
        builder: (context, queryResult) {
          final files = queryResult.items
              .map((item) => Map<String, dynamic>.from(item.value))
              .toList();

          if (files.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 72, color: Colors.white24),
                    SizedBox(height: 16),
                    Text(
                      'Share your first PeerReal Moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the camera button to take your PeerReal moment!😜',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final doc = files[index];
              return PeerRealPostCard(
                key: ValueKey(doc['createdAt']),
                doc: doc,
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    DittoService.instance.dispose();
    super.dispose();
  }
}

// Widget für Bottom-Navigation-Item (Helper class)
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white54;
    final fontWeight = selected ? FontWeight.w600 : FontWeight.w400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
