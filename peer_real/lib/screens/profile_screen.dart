import 'package:flutter/material.dart';
import 'package:PeerReal/services/ditto_service.dart';
import '../services/logger_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final service = DittoService.instance;
    final name =
        await service.getDisplayNameForPeer(service.localPeerId);
    if (!mounted) return;
    setState(() {
      _displayName = name;
    });
  }

  Future<void> _pickDisplayName(BuildContext context) async {
    final controller = TextEditingController(text: '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose your name'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter a unique name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (name == null || name == '' || name.trim().isEmpty) return;

    final ok = await DittoService.instance.setDisplayName(name);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _displayName = name.trim();
      });
      logger.i('✅ Display name set to "$name"');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Name set to "$name"'
            : 'Name "$name" is already taken'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName;
    final handle =
        name != null && name.isNotEmpty ? '@$name' : '@username';

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050A),
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // später: Settings Screen
            },
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name
            Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white12,
                  child:
                      Icon(Icons.person, size: 32, color: Colors.white70),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'You',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      handle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Button zum Namen ändern
            OutlinedButton.icon(
              onPressed: () => _pickDisplayName(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Change display name'),
            ),

            const SizedBox(height: 24),

            // Memories / Posts / Friends
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProfileStat(label: 'Moments', value: '12'),
                _ProfileStat(label: 'Friends', value: '8'),
                _ProfileStat(label: 'Streak', value: '3'),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Latest moments',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            const Expanded(
              child: Center(
                child: Text(
                  'Your PeerReal Memories will be added here later ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
