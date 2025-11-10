// lib/widgets/product_card.dart

import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final double price;
  final String imageUrl;
  final VoidCallback onTap; // Required for tappability/navigation

  const ProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gumamit ng InkWell para sa ripple effect at onTap function
    return InkWell(
      onTap: onTap,
      child: Card(
        // Card properties (elevation, shape, color) are now handled by ThemeData
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- IMAGE SECTION ---
            // Use Expanded with flex=3 for 60% of the card height
            Expanded(
              flex: 3, //
              child: ClipRRect(
                // Use a smaller border radius to match the Card's theme
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), // Matches Card radius
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                  },
                ),
              ),
            ),

            // --- INFO SECTION ---
            // Use Expanded with flex=2 for 40% of the card height
            Expanded(
              flex: 2, //
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800], // Dark grey text
                      ),
                      maxLines: 2, // Allow up to 2 lines for the name
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Spacer to push the price to the bottom
                    const Spacer(),

                    // Price
                    Text(
                      '₱${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).primaryColor, // Use kBrown for the price
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}