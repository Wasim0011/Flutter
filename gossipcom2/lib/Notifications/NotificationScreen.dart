import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),

        ),
        backgroundColor: Colors.transparent,

        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notification')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when someone gives you vibe points!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final notification = snapshot.data!.docs[index];
                final data = notification.data() as Map<String, dynamic>;

                return NotificationTile(
                  notificationId: notification.id,
                  userId: currentUserId,
                  data: data,
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('isDeleted', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notifications as read: $e')),
      );
    }
  }



}

class NotificationTile extends StatelessWidget {
  final String notificationId;
  final String userId;
  final Map<String, dynamic> data;

  NotificationTile({
    super.key,
    required this.notificationId,
    required this.userId,
    required this.data,
  });


  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;


  Future<void> _deleteNotification(BuildContext context) async {
    try {
      // final batch = FirebaseFirestore.instance.batch();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isDeleted': true});


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .doc(notificationId)
                  .update({'isDeleted': false});
            },
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isRead = data['isRead'] ?? false;
    final timestamp = data['timestamp'] as Timestamp?;
    final senderName = data['senderName'] ?? 'Someone';
    final points = data['points'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? Colors.grey[200]!
              : const Color(0xFF1976D2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.stars_rounded,
            color: Color(0xFF1976D2),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              data['title'] ?? 'Vibe Points Received!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteNotification(context);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            )

          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              data['message'] ?? '$senderName gave you $points vibe points!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$points points',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _markAsRead(),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _markAsRead() async {
    if (data['isRead'] == true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
