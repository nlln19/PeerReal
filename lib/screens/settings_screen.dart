import 'package:flutter/material.dart';
import 'package:PeerReal/services/ditto_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = DittoService.instance.displayName;
  }

  Future<void> _changeDisplayName() async {
    final controller = TextEditingController(text: _currentName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose your name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter a unique name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    final ok = await DittoService.instance.setDisplayName(newName);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _currentName = newName;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Name set to "$newName"' : 'Name "$newName" is already taken',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameLabel = _currentName ?? 'not set yet';

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050A),
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text(
              'Display name',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              nameLabel,
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.edit, color: Colors.white70),
            onTap: _changeDisplayName,
          ),
          const Divider(color: Colors.white12),
          // Platzhalter für zukünftige Settings
          const ListTile(
            leading: Icon(Icons.notifications_none, color: Colors.white),
            title: Text(
              'Notifications (coming soon)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
