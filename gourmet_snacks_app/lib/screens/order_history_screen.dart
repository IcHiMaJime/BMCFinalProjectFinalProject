import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color.fromARGB(255, 47, 137, 214);

  String? get _userId => _auth.currentUser?.uid;

  Stream<QuerySnapshot> _fetchOrders() {
    if (_userId == null) return const Stream.empty(); // Return empty stream if no user

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: _userId)
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> orderData, String orderId) {
    final List<dynamic> items = orderData['items'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Order Details (ID: ${orderId.substring(0, 8)}...)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemPrice = (item['price'] as num).toDouble();
              final itemQuantity = item['quantity'] as int;
              return ListTile(
                title: Text('${item['name']} (${itemQuantity}x)'),
                trailing: Text('₱${(itemPrice * itemQuantity).toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Text('Please log in to view your order history.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred while fetching your orders.'));
          }

          final orderDocs = snapshot.data!.docs;

          if (orderDocs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text(
                        'You have not placed any orders yet.',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: orderDocs.length,
            itemBuilder: (ctx, index) {
              final orderDoc = orderDocs[index];
              final orderData = orderDoc.data() as Map<String, dynamic>;
              final String orderId = orderDoc.id;

              final Timestamp timestamp = orderData['orderDate'] as Timestamp;
              final DateTime orderDate = timestamp.toDate();
              final String formattedDate = DateFormat('MMM d, yyyy h:mm a').format(orderDate);
              final double totalPrice = orderData['totalPrice'] as double;
              final String status = orderData['status'] as String;
              final Color statusColor = status == 'Pending' ? Colors.orange : Colors.green;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  onTap: () => _showOrderDetails(context, orderData, orderId),

                  // Simpler display
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(
                      '${orderData['items'].length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),

                  title: Text(
                    'Order Total: ₱${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    'Status: $status\nDate: $formattedDate',
                  ),

                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}