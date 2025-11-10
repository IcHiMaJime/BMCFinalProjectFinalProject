import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Mark ALL as read (manual)
  Future<void> _markAllAsRead() async {
    if (_user == null) return;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _user!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No unread notifications.')));
        }
        return;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications marked as read!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error marking all as read: $e')));
      }
    }
  }

  // ✅ Mark SINGLE notification as read
  void _markSingleAsRead(String docId) {
    _firestore
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true}).catchError((e) {
      debugPrint('Error marking single notification as read: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All As Read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _user == null
          ? const Center(child: Text('Please log in.'))
          : StreamBuilder<QuerySnapshot>(
        // ✅ FIX: Do not order by 'createdAt' directly — handle nulls safely
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('You have no notifications.'));
          }

          final docs = snapshot.data!.docs;

          // ✅ Sort manually to handle null createdAt
          docs.sort((a, b) {
            final tsA = a['createdAt'] as Timestamp?;
            final tsB = b['createdAt'] as Timestamp?;
            if (tsA == null && tsB == null) return 0;
            if (tsA == null) return 1; // put nulls last
            if (tsB == null) return -1;
            return tsB.compareTo(tsA);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              final timestamp = data['createdAt'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat('MM/dd/yy hh:mm a')
                  .format(timestamp.toDate())
                  : 'Just now';

              final bool isRead = data['isRead'] == true;

              return ListTile(
                onTap: isRead
                    ? null
                    : () => _markSingleAsRead(docId),
                leading: isRead
                    ? const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 20)
                    : const Icon(Icons.circle,
                    color: Colors.deepPurple, size: 12),
                title: Text(
                  data['title'] ?? 'No Title',
                  style: TextStyle(
                    fontWeight:
                    isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${data['body'] ?? ''}\n$formattedDate',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
