import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const OrderCard({
    super.key,
    required this.orderData,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    // Cast the Firestore Timestamp to DateTime
    final Timestamp timestamp = orderData['orderDate'] as Timestamp;
    final DateTime orderDate = timestamp.toDate();
    // Use the DateFormat class to format the date
    final String formattedDate = DateFormat('MM/dd/yyyy - hh:mm a').format(orderDate);

    final double totalPrice = orderData['totalPrice'] as double;
    final String status = orderData['status'] as String;
    final List<dynamic> items = orderData['items'] as List<dynamic>;

    final Color statusColor = status == 'Pending' ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'Order ID: ${orderId.substring(0, 8)}...',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: $formattedDate', style: const TextStyle(fontSize: 12)),
            Text('Items: ${items.length}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),

        children: items.map<Widget>((item) {
          // Tiyakin na ang price ay double
          final itemPrice = (item['price'] as num).toDouble();
          final itemQuantity = item['quantity'] as int;

          return ListTile(
            leading: Text('${itemQuantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
            title: Text(item['name'] as String),
            trailing: Text('₱${(itemPrice * itemQuantity).toStringAsFixed(2)}'),
          );
        }).toList(),
      ),
    );
  }
}