import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Same room id for both users (ids sorted so the order never matters).
  String chatRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  // Enhancement 1: all registered users EXCEPT the logged-in user.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final myUid = _firebaseAuth.currentUser?.uid;
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data())
          .where((user) => user['uid'] != myUid)
          .toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final user = _firebaseAuth.currentUser!;
    final newMessage = MessageModel(
      senderId: user.uid,
      senderEmail: user.email ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: Timestamp.now(),
    );
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(user.uid, receiverId))
        .collection('messages')
        .add(newMessage.toMap());
  }

  // includeMetadataChanges lets the UI know which messages are still being
  // sent (hasPendingWrites) vs delivered.
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
      String userId, String otherUserId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(userId, otherUserId))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  /// Marks messages sent to me by [otherUserId] as seen.
  Future<void> markAsRead(String otherUserId) async {
    final me = _firebaseAuth.currentUser?.uid;
    if (me == null) return;
    final unread = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(me, otherUserId))
        .collection('messages')
        .where('receiverId', isEqualTo: me)
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}