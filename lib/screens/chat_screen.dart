import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

/// Chat List UI (second bottom-navigation tab).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> user) {
    final full =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    final username = (user['username'] ?? '').toString();
    if (username.isNotEmpty) return username;
    return (user['email'] ?? 'Unknown').toString();
  }

  // Enhancement 2: filter by name, username or email.
  bool _matches(Map<String, dynamic> user) {
    if (_query.isEmpty) return true;
    final haystack = [
      user['firstName'],
      user['lastName'],
      user['username'],
      user['email'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');
    return haystack.contains(_query);
  }

  Widget _centered(String text, {IconData? icon}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 56, color: Colors.grey),
              if (icon != null) const SizedBox(height: 12),
              CustomText(text, fontSize: 16, textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const CustomText('Chats',
            fontSize: 22, fontWeight: FontWeight.bold),
      ),
      body: _userService.currentUser == null
          ? _centered(
              'Chat needs a Firebase account.\nLog out and sign in using the Firebase option.',
              icon: Icons.lock_outline)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.cancel),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }
                      if (snapshot.hasError) {
                        return _centered(
                            'Error loading users: ${snapshot.error}',
                            icon: Icons.error_outline);
                      }
                      final all = snapshot.data ?? [];
                      if (all.isEmpty) {
                        return _centered(
                            'No other users yet.\nCreate another account to start chatting.',
                            icon: Icons.people_outline);
                      }
                      final users = all.where(_matches).toList();
                      if (users.isEmpty) {
                        return _centered('No users match "$_query"',
                            icon: Icons.search_off);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final name = _displayName(user);
                          return Card(
                            child: ListTile(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatDetailScreen(tappedUser: user),
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: CustomText(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              title: CustomText(name,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: CustomText(
                                  (user['email'] ?? 'No email').toString(),
                                  fontSize: 12,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}