import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gourmet_snacks_app/providers/cart_provider.dart';
import 'package:gourmet_snacks_app/screens/order_success_screen.dart';
import 'package:google_fonts/google_fonts.dart';

enum PaymentMethod { card, gcash, bank }

class PaymentScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 2. State variables
  PaymentMethod? _selectedMethod = PaymentMethod.card;
  bool _isLoading = false;


  final Color bluePrimary = Colors.blue.shade700;
  final Color kUniqueNavyText = const Color(0xFF1A237E);

  // 3. Mock Payment Logic: Simulate a 3-second API call
  Future<void> _processPayment(BuildContext context) async {
    if (_selectedMethod == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Simulate network delay (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      // Step 2: Place the order (This calls the Firestore logic and clears the cart)
      final cart = Provider.of<CartProvider>(context, listen: false);
      await cart.placeOrder();

      // Step 3: Navigate to success screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const OrderSuccessScreen(),
          ),
              (Route<dynamic> route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        // Handle error: show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment/Order failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 4. Helper function to build the radio list tiles
  Widget _buildPaymentTile(
      String title, PaymentMethod method, IconData icon) {
    return RadioListTile<PaymentMethod>(
      title: Text(
          title,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w600,
            color: kUniqueNavyText,
          )
      ),
      secondary: Icon(icon, color: bluePrimary),
      value: method,
      groupValue: _selectedMethod,
      onChanged: (PaymentMethod? value) {
        setState(() {
          _selectedMethod = value;
        });
      },
      activeColor: bluePrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Final Total:',
                        style: GoogleFonts.lato(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kUniqueNavyText,
                        )
                    ),
                    Text(
                      '₱${widget.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: bluePrimary
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Text(
              'Select Payment Method:',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kUniqueNavyText,
              ),
            ),
            const SizedBox(height: 10),

            // Payment Options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPaymentTile(
                      'Credit / Debit Card',
                      PaymentMethod.card,
                      Icons.credit_card,
                    ),
                    _buildPaymentTile(
                      'GCash',
                      PaymentMethod.gcash,
                      Icons.phone_android,
                    ),
                    _buildPaymentTile(
                      'Bank Transfer',
                      PaymentMethod.bank,
                      Icons.account_balance,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // --- Bottom Pay Button ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: (_isLoading || _selectedMethod == null)
              ? null
              : () => _processPayment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: bluePrimary, // Blue Primary button
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3.0,
            ),
          )
              : Text(
            'Pay Now',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}