import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Stream<QuerySnapshot> getNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notification')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> markAsRead(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notification')
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<int> getUnreadCount(String userId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notification')
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }
}
