import 'package:flutter/material.dart';
import 'package:ditto_live/ditto_live.dart';
import '../services/dql_builder_service.dart';
import '../services/ditto_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _tabIndex = 0; // 0 = Freunde, 1 = Anfragen
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final ditto = DittoService.instance.ditto;
    final me = DittoService.instance.localPeerId;

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050A),
        elevation: 0,
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              // Optional: eigenen Add-Flow später
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Freunde hinzufügen kommt über die Suche 😜'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Friends/Requests Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FriendsTabButton(
                label: 'Friends',
                selected: _tabIndex == 0,
                onTap: () => setState(() => _tabIndex = 0),
              ),
              const SizedBox(width: 8),
              _FriendsTabButton(
                label: 'Requests',
                selected: _tabIndex == 1,
                onTap: () => setState(() => _tabIndex = 1),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Suche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _tabIndex == 0
                    ? 'Search for friends or users'
                    : 'Search in requests',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF11111A),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.trim().toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _tabIndex == 0
                ? (_searchTerm.isEmpty
                    ? _buildFriendsList(ditto, me)
                    : _buildProfileSearchResults(ditto, me))
                : _buildRequestsList(ditto, me),
          ),
        ],
      ),
    );
  }

  /// Hilfsfunktion: gibt den "anderen" Peer einer Freundschaft zurück
  String _otherPeerId(Map<String, dynamic> friendship, String me) {
    final from = friendship['fromPeerId'] as String?;
    final to = friendship['toPeerId'] as String?;
    if (from == null || to == null) return 'Unknown';
    return from == me ? to : from;
  }

  Widget _buildFriendsList(Ditto ditto, String me) {
    return DqlBuilderService(
      ditto: ditto,
      query: '''
        SELECT * FROM friendships
        WHERE status = "accepted"
          AND (fromPeerId = :me OR toPeerId = :me)
        ORDER BY updatedAt DESC
      ''',
      queryArgs: {'me': me},
      builder: (context, result) {
        final friends = result.items
            .map((item) => Map<String, dynamic>.from(item.value))
            .toList();

        if (friends.isEmpty) {
          return const Center(
            child: Text(
              'No friends added yet.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          itemCount: friends.length,
          separatorBuilder: (_, __) => const Divider(
            color: Colors.white10,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final friendship = friends[index];
            final otherId = _otherPeerId(friendship, me);

            return FutureBuilder<String>(
              future: DittoService.instance.getDisplayNameForPeer(otherId),
              builder: (context, snap) {
                final displayName =
                    snap.data ?? otherId; // Fallback: PeerId falls noch lädt

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, color: Colors.white70),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tap to view profile',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () {
                    // später: Friend-Profile öffnen
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Suchergebnisse über alle Profile (Name-Suche, um Anfragen zu schicken)
  Widget _buildProfileSearchResults(Ditto ditto, String me) {
    return DqlBuilderService(
      ditto: ditto,
      query: '''
        SELECT * FROM profiles
        ORDER BY displayName ASC
      ''',
      builder: (context, result) {
        var profiles = result.items
            .map((item) => Map<String, dynamic>.from(item.value))
            .toList();

        // eigenen Eintrag rausfiltern
        profiles.removeWhere((p) => p['_id'] == me);

        // nach displayName filtern
        if (_searchTerm.isNotEmpty) {
          profiles = profiles.where((p) {
            final name =
                (p['displayName'] as String? ?? '').toLowerCase();
            return name.contains(_searchTerm);
          }).toList();
        }

        if (profiles.isEmpty) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          itemCount: profiles.length,
          separatorBuilder: (_, __) => const Divider(
            color: Colors.white10,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final p = profiles[index];
            final peerId = p['_id'] as String? ?? '';
            final name = p['displayName'] as String? ?? peerId;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(Icons.person_add, color: Colors.white70),
              ),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                peerId,
                style:
                    const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.person_add_alt_1,
                    color: Colors.greenAccent),
                onPressed: () async {
                  await DittoService.instance.sendFriendRequest(peerId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Friend request sent to $name'),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList(Ditto ditto, String me) {
    return DqlBuilderService(
      ditto: ditto,
      query: '''
        SELECT * FROM friendships
        WHERE toPeerId = :me AND status = "pending"
        ORDER BY createdAt DESC
      ''',
      queryArgs: {'me': me},
      builder: (context, result) {
        var requests = result.items
            .map((item) => Map<String, dynamic>.from(item.value))
            .toList();

        if (requests.isEmpty) {
          return const Center(
            child: Text(
              'No requests received.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(
            color: Colors.white10,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final req = requests[index];
            final fromPeerId = req['fromPeerId'] as String? ?? 'Unknown';

            return FutureBuilder<String>(
              future:
                  DittoService.instance.getDisplayNameForPeer(fromPeerId),
              builder: (context, snap) {
                final name =
                    snap.data ?? fromPeerId; // falls Profil noch nicht da

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person_add, color: Colors.white70),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'sent you a friend request',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  // später: Accept/Decline
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FriendsTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FriendsTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? Colors.white : const Color(0xFF11111A);
    final textColor = selected ? Colors.black : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
