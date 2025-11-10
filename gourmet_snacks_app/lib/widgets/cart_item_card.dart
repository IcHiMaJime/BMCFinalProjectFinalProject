// lib/widgets/cart_item_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gourmet_snacks_app/providers/cart_provider.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({
    super.key,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context) {
    // Access CartProvider to delete the item
    final cart = Provider.of<CartProvider>(context, listen: false);
    final double totalPrice = cartItem.price * cartItem.quantity;
    final Color primaryColor = const Color.fromARGB(255, 47, 137, 214);

    // Gumamit ng Dismissible para sa swipe-to-delete functionality
    return Dismissible(
      key: ValueKey(cartItem.id), // Kailangan ng unique key
      direction: DismissDirection.endToStart,

      // Ang background na lalabas kapag nag-swipe
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),

      // Confirmation dialog bago mag-delete
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to remove the item from the cart?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false); // Huwag i-dismiss
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true); // I-dismiss
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      },

      // Ang mangyayari kapag nag-dismiss
      onDismissed: (direction) {
        // Tiyakin na nag-re-remove lang kapag nag-swipe (para maiwasan ang double delete)
        if (direction == DismissDirection.endToStart) {
          // IKINORREK: Gumamit ng cartItem.id imbes na cartItem.productId
          cart.removeItem(cartItem.id);
        }

        // Optional: Show a snackbar after removing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cartItem.name} removed from cart.'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      },

      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FittedBox(
                  child: Text(
                    '₱${totalPrice.toStringAsFixed(0)}', // Total price ng item
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            title: Text(cartItem.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Price: ₱${cartItem.price.toStringAsFixed(2)} | Quantity: ${cartItem.quantity}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () {
                // IKINORREK: Gumamit ng cartItem.id imbes na cartItem.productId
                cart.removeItem(cartItem.id);
              },
            ),
          ),
        ),
      ),
    );
  }
}