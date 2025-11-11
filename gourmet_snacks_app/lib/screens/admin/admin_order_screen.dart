import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color _screenColor = Colors.lightBlue.shade300;
  final Color kUniqueNavyText = const Color(0xFF1A237E);

  Stream<QuerySnapshot> _fetchOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  Future<void> _updateOrderStatus(
      String orderId, String newStatus, String userId) async {
    try {
      // 1. Update the order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // 2. Create a notification for that user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Order Status Updated',
        'body': 'Your order ($orderId) has been updated to "$newStatus".',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status or creating notification: $e')),
      );
    }
  }

  void _showStatusDialog(String orderId, String currentStatus, String userId) {
    final List<String> statuses = [
      'Pending',
      'Processing',
      'Shipped',
      'Delivered',
      'Cancelled'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Use GoogleFonts and Navy Text
        title: Text('Update Order Status', style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: kUniqueNavyText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              title: Text(status, style: GoogleFonts.lato(color: kUniqueNavyText)),
              trailing: status == currentStatus
                  ? Icon(Icons.check, color: _screenColor) // Themed check icon
                  : null,
              onTap: () async {
                if (status != currentStatus) {
                  await _updateOrderStatus(orderId, status, userId);
                }
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // default status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade700;
      case 'Processing':
        return Colors.blue.shade700;
      case 'Shipped':
        return Colors.deepPurple.shade700;
      case 'Delivered':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text('Manage All Orders', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold)), // Use GoogleFonts
        backgroundColor: _screenColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.lato())); // Use GoogleFonts
          }

          final orderDocs = snapshot.data!.docs;

          if (orderDocs.isEmpty) {
            return Center(
              child: Text('No orders found yet.',
                  style: GoogleFonts.lato(fontSize: 18, color: Colors.grey)), // Use GoogleFonts
            );
          }

          return ListView.builder(
            itemCount: orderDocs.length,
            itemBuilder: (ctx, index) {
              final orderDoc = orderDocs[index];
              final orderData = orderDoc.data() as Map<String, dynamic>;
              final String orderId = orderDoc.id;
              final String userId = orderData['userId'] ?? '';
              final double totalPrice =
              (orderData['totalPrice'] ?? 0).toDouble();
              final String status = orderData['status'] ?? 'Pending';

              final Timestamp timestamp =
                  orderData['orderDate'] as Timestamp? ??
                      Timestamp.now();
              final String formattedDate =
              DateFormat('MM/dd/yy h:mm a').format(timestamp.toDate());

              return ListTile(
                onTap: () => _showStatusDialog(orderId, status, userId),
                leading: CircleAvatar(
                  backgroundColor: _screenColor,
                  child: Text(
                    '${orderData['items']?.length ?? 0}',
                    style: GoogleFonts.lato(
                        color: Colors.white, fontWeight: FontWeight.bold), // Use GoogleFonts
                  ),
                ),
                title: Text(
                  'ID: ${orderId.substring(0, 8)}... | ₱${totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: kUniqueNavyText),
                ),
                subtitle:
                Text(
                  'User: ${userId.isNotEmpty ? userId.substring(0, 8) : 'N/A'} | Date: $formattedDate',
                  style: GoogleFonts.lato(color: Colors.grey.shade600), // Use GoogleFonts
                ),
                trailing: Chip(
                  label: Text(
                    status,
                    style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), // Use GoogleFonts
                  ),
                  backgroundColor: _getStatusColor(status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}