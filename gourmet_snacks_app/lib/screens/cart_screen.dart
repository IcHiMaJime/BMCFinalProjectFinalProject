import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gourmet_snacks_app/providers/cart_provider.dart';
import 'package:gourmet_snacks_app/widgets/cart_item_card.dart';
import 'package:gourmet_snacks_app/screens/payment_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Widget _buildPriceRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: GoogleFonts.lato(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bluePrimary = Colors.blue.shade700;
    const Color kUniqueNavyText = Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final cartItems = cart.items;
          final subtotal = cart.subtotal;
          final vatAmount = cart.vat;
          final totalWithVat = cart.totalPriceWithVat;

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: bluePrimary.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty!',
                    style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: kUniqueNavyText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time to find your new favorite snack.',
                    style: GoogleFonts.lato(fontSize: 16, color: Colors.blueGrey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: <Widget>[
              // Checkout Summary and Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        _buildPriceRow('Subtotal', subtotal, kUniqueNavyText),
                        _buildPriceRow('VAT (12%)', vatAmount, kUniqueNavyText),
                        const Divider(height: 20, thickness: 1.5),
                        _buildPriceRow(
                          'Order Total',
                          totalWithVat,
                          bluePrimary,
                          isTotal: true,
                        ),
                        const SizedBox(height: 20),

                        // Proceed to Payment Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  // I-pass ang VAT-inclusive total
                                  totalAmount: totalWithVat,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bluePrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'PROCEED TO PAYMENT',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // List of Cart Items
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (ctx, i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: CartItemCard(
                        cartItem: cartItems[i],
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}