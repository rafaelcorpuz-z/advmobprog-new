import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

/// Chat Detail Screen - redesigned with animated bubbles and sending states.
class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({super.key, required this.tappedUser});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  late final String _currentUserId;
  late final String _otherUserId;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = UserService().currentUser!.uid;
    _otherUserId = (widget.tappedUser['uid'] ?? '').toString();
    _chatService.markAsRead(_otherUserId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _name {
    final full =
        '${widget.tappedUser['firstName'] ?? ''} ${widget.tappedUser['lastName'] ?? ''}'
            .trim();
    if (full.isNotEmpty) return full;
    final username = (widget.tappedUser['username'] ?? '').toString();
    return username.isNotEmpty
        ? username
        : (widget.tappedUser['email'] ?? 'Unknown').toString();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear(); // optimistic: bubble shows "Sending..." right away
    _msgFocus.requestFocus();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    try {
      await _chatService.sendMessage(_otherUserId, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _markSeenIfNeeded(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final hasUnread = docs.any((d) {
      final m = d.data();
      return m['receiverId'] == _currentUserId && m['read'] != true;
    });
    if (hasUnread && !_marking) {
      _marking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _chatService.markAsRead(_otherUserId);
        _marking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'avatar_$_otherUserId',
              child: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  Text((widget.tappedUser['email'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.getMessages(_currentUserId, _otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading messages: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                _markSeenIfNeeded(docs);

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.waving_hand_outlined,
                            size: 56, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text('Say hi to $_name',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final isMe = data['senderId'] == _currentUserId;
                    return _MessageBubble(
                      key: ValueKey(doc.id),
                      text: (data['message'] ?? '').toString(),
                      isMe: isMe,
                      time: data['timestamp'] is Timestamp
                          ? (data['timestamp'] as Timestamp).toDate()
                          : null,
                      isSending: doc.metadata.hasPendingWrites,
                      isSeen: data['read'] == true,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _msgCtrl,
            focusNode: _msgFocus,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

/// One chat bubble: fades + slides in, shows time and delivery state.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    required this.isSending,
    required this.isSeen,
  });

  final String text;
  final bool isMe;
  final DateTime? time;
  final bool isSending;
  final bool isSeen;

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isMe ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = isMe ? scheme.onPrimary : scheme.onSurface;
    final metaColor = isMe
        ? scheme.onPrimary.withValues(alpha: 0.75)
        : scheme.onSurfaceVariant;

    // Sending / delivered / seen indicator (only for my messages).
    Widget? status;
    if (isMe) {
      if (isSending) {
        status = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 13, color: metaColor),
            const SizedBox(width: 3),
            Text('Sending...',
                style: TextStyle(fontSize: 10.5, color: metaColor)),
          ],
        );
      } else if (isSeen) {
        status = const Icon(Icons.done_all, size: 15, color: Colors.lightBlueAccent);
      } else {
        status = Icon(Icons.done, size: 15, color: metaColor);
      }
    }

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(text.isNotEmpty ? text : '[empty]',
                style: TextStyle(fontSize: 15, color: textColor, height: 1.3)),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (time != null)
                Text(_formatTime(time!),
                    style: TextStyle(fontSize: 10.5, color: metaColor)),
              if (status != null) ...[
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(isSending ? 'sending' : (isSeen ? 'seen' : 'sent')),
                    child: status,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Fade + slide in (from the right for me, from the left for them).
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((isMe ? 24 : -24) * (1 - value), 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canSend ? scheme.primary : scheme.surfaceContainerHighest,
                  ),
                  child: IconButton(
                    tooltip: 'Send',
                    icon: Icon(Icons.send_rounded,
                        color: canSend ? scheme.onPrimary : scheme.outline),
                    onPressed: canSend ? onSend : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}