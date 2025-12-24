import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:PeerReal/services/ditto_service.dart';

enum AppThemeMode { dark, light }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentName;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentName = DittoService.instance.displayName;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
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

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications enabled' : 'Notifications disabled',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text(
            'This will delete your profile, friendships and all your Reals on this device.\n\n'
            'Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final ok = await DittoService.instance.deleteAccountAndData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Account deleted on this device' : 'Failed to delete account',
        ),
      ),
    );

    if (ok) {
      Navigator.of(context).pop(); // Settings schließen
    }
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

          // Display name
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

          // Notifications toggle
          SwitchListTile.adaptive(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            secondary: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _notificationsEnabled ? 'Enabled' : 'Disabled',
              style: const TextStyle(color: Colors.white54),
            ),
            activeColor: Colors.white,
          ),
          const Divider(color: Colors.white12),

          // Delete account
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text(
              'Remove your profile, friendships and Reals on this device',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}
