import 'package:ecommerce_app/providers/wishlist_provider.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF425A87), // Dark blue
                Color(0xFF397DED), // Bright blue
              ],
            ),
          ),
        ),
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                'Please log in to view your wishlist',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Consumer<WishlistProvider>(
              builder: (context, wishlist, child) {
                if (wishlist.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your wishlist is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add products to your wishlist to save them for later',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: wishlist.items.length,
                  itemBuilder: (context, index) {
                    final item = wishlist.items[index];
                    final isOutOfStock = item.stock == 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: InkWell(
                        onTap: () async {
                          // Fetch product data from Firestore
                          try {
                            final productDoc = await FirebaseFirestore.instance
                                .collection('products')
                                .doc(item.productId)
                                .get();

                            if (productDoc.exists && context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productData: productDoc.data()!,
                                    productId: item.productId,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error loading product: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          size: 16,
                                          color: isOutOfStock
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOutOfStock
                                              ? 'Out of Stock'
                                              : '${item.stock} in stock',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOutOfStock
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              Column(
                                children: [
                                  // Remove from wishlist
                                  IconButton(
                                    icon: const Icon(Icons.favorite,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await wishlist.removeFromWishlist(
                                          item.productId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Removed from wishlist'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  // Add to cart (if in stock)
                                  if (!isOutOfStock)
                                    Consumer<CartProvider>(
                                      builder: (context, cart, child) {
                                        return IconButton(
                                          icon: const Icon(Icons
                                              .shopping_cart_outlined),
                                          onPressed: () {
                                            cart.addItem(
                                              item.productId,
                                              item.name,
                                              item.price,
                                              1,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Added ${item.name} to cart'),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

