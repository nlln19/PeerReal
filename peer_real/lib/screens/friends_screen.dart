import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _tabIndex = 0; // 0 = Freunde, 1 = Anfragen

  @override
  Widget build(BuildContext context) {
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
              // später: Friend-Add-Flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Freunde hinzufügen kommt später😜'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Friends / Requests
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
                hintText: 'Search for friends',
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
                // später: Filter implementieren
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _tabIndex == 0 ? _buildFriendsList() : _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    // Platzhalter-Liste für friends
    final friends = [
      'Shlenny',
      'Shlucca',
      'Shmarvin',
      'Sheli',
      'Shdario',
      'Shnillan',
    ];

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
        final name = friends[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, color: Colors.white70),
          ),
          title: Text(
            name,
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
  }

  Widget _buildRequestsList() {
    // Platzhalter: keine Anfragen
    return const Center(
      child: Text(
        'No requests received.',
        style: TextStyle(color: Colors.white54),
      ),
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
