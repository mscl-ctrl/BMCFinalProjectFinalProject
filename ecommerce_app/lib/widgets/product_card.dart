import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/providers/wishlist_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final double price;
  final String imageUrl;
  final VoidCallback onTap;
  final double? rating; // Optional rating (0.0 to 5.0)
  final String? productId; // Product ID for wishlist
  final int? stock; // Stock count

  const ProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.onTap,
    this.rating, // Optional, defaults to null
    this.productId,
    this.stock,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final fontSize = isMobile ? 14.0 : 16.0;
    final priceFontSize = isMobile ? 13.0 : 15.0;
    final padding = isMobile ? 8.0 : 10.0;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOutOfStock = stock != null && stock == 0;
    
    // 1. The Card will get its style from our new 'cardTheme'
    return InkWell(
      onTap: onTap,
      child: Card(
        // 2. The theme's 'clipBehavior' will handle the clipping
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3. This Expanded makes the image take up most of the space
            Expanded(
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover, // This makes the image fill its box
                    width: double.infinity,
                    height: double.infinity,
                    
                    // Show a loading spinner
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    
                    // Show an error icon
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                  // Out of stock overlay
                  if (isOutOfStock)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  // Wishlist heart button (always visible, but more prominent when out of stock)
                  if (currentUser != null && productId != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlist, child) {
                          final isWishlisted = wishlist.items.any((item) => item.productId == productId);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                try {
                                  await wishlist.toggleWishlist(
                                    productId: productId!,
                                    name: productName,
                                    price: price,
                                    imageUrl: imageUrl,
                                    stock: stock ?? 0,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isWishlisted
                                              ? 'Removed from wishlist'
                                              : 'Added to wishlist',
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? Colors.red.withOpacity(0.9)
                                      : Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isWishlisted
                                      ? Colors.red
                                      : (isOutOfStock ? Colors.white : Colors.red),
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // 4. This holds the text with minimal spacing
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    maxLines: 2, // Allow two lines for the name
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Small spacing between name and stars
                  // Review Stars
                  _buildStarRating(rating ?? 0.0, isMobile ? 12.0 : 14.0),
                  const SizedBox(height: 4), // Small spacing between stars and price
                  // Price
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: priceFontSize,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, double starSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        ...List.generate(5, (index) {
          if (rating == 0.0) {
            // Show empty stars if no rating
            return Icon(
              Icons.star_border,
              size: starSize,
              color: Colors.amber,
            );
          }
          if (index < rating.floor()) {
            // Full star
            return Icon(
              Icons.star,
              size: starSize,
              color: Colors.amber,
            );
          } else if (index < rating.ceil() && rating % 1 != 0) {
            // Half star
            return Icon(
              Icons.star_half,
              size: starSize,
              color: Colors.amber,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_border,
              size: starSize,
              color: Colors.amber,
            );
          }
        }),
        // Numeric rating
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: starSize * 0.85,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
