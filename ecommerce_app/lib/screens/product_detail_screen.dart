import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/providers/wishlist_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Change StatelessWidget to StatefulWidget
class ProductDetailScreen extends StatefulWidget {
  
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  // 2. Create the State class
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

// 3. Rename the main class to _ProductDetailScreenState and extend State
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  
  // 4. ADD OUR NEW STATE VARIABLE FOR QUANTITY
  int _quantity = 1;
  double? _userRating;
  bool _hasPurchased = false;
  bool _isCheckingPurchase = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfPurchased();
    _loadUserRating();
  }

  Future<void> _checkIfPurchased() async {
    if (_currentUser == null) {
      setState(() {
        _isCheckingPurchase = false;
        _hasPurchased = false;
      });
      return;
    }

    try {
      final userId = _currentUser!.uid;
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      bool purchased = false;
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final items = orderData['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            if (item['id'] == widget.productId) {
              purchased = true;
              break;
            }
          }
        }
        if (purchased) break;
      }

      setState(() {
        _hasPurchased = purchased;
        _isCheckingPurchase = false;
      });
    } catch (e) {
      setState(() {
        _hasPurchased = false;
        _isCheckingPurchase = false;
      });
    }
  }

  Future<void> _loadUserRating() async {
    if (_currentUser == null) return;

    try {
      final userId = _currentUser!.uid;
      final ratingDoc = await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('ratings')
          .doc(userId)
          .get();

      if (ratingDoc.exists) {
        setState(() {
          _userRating = (ratingDoc.data()?['rating'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      // Error loading rating
    }
  }


  // 1. ADD THIS FUNCTION
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // 2. ADD THIS FUNCTION
  void _decrementQuantity() {
    // We don't want to go below 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // 5. The build method will go inside here
  @override
  Widget build(BuildContext context) {
    // 1. We now access productData using 'widget.'
    final String name = widget.productData['name'];
    final String description = widget.productData['description'];
    final String imageUrl = widget.productData['imageUrl'];
    final double price = (widget.productData['price'] as num).toDouble();

    // 2. Get the CartProvider (same as before)
    final cart = Provider.of<CartProvider>(context, listen: false);

    final currentUser = FirebaseAuth.instance.currentUser;
    final stock = widget.productData['stock'] != null 
        ? (widget.productData['stock'] as num).toInt() 
        : null;
    final isOutOfStock = stock != null && stock == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image, size: 100));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3E5AB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF5FEFD),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  Text(
                    'About this item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5F5DC),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFFFBFCF8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Rating Section
                  _buildRatingSection(),
                  const SizedBox(height: 20),
                  // 4. --- ADD THIS NEW SECTION ---
                  //    (before the "Add to Cart" button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 5. DECREMENT BUTTON
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity,
                      ),
                      
                      // 6. QUANTITY DISPLAY
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity', // 7. Display our state variable
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFF0),
                          ),
                        ),
                      ),
                      
                      // 8. INCREMENT BUTTON
                      IconButton.filled(
                        icon: const Icon(Icons.add, color: Color(0xFF3E424B)),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // --- END OF NEW SECTION ---

                  // 9. Add to Cart and Wishlist buttons side by side
                  Row(
                    children: [
                      // Add to Cart button (expanded to prevent overlap)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isOutOfStock ? null : () {
                            // 10. --- THIS IS THE UPDATED LOGIC ---
                            //    We now pass the _quantity from our state
                            cart.addItem(
                              widget.productId,
                              name,
                              price,
                              _quantity, // 11. Pass the selected quantity
                            );

                            // 12. Update the SnackBar message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added $_quantity x $name to cart!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF3E424B)),
                          label: Text(
                            isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                            style: const TextStyle(color: Color(0xFF3E424B)),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Wishlist button
                      if (currentUser != null)
                        Expanded(
                          flex: 1,
                          child: Consumer<WishlistProvider>(
                            builder: (context, wishlist, child) {
                              final isWishlisted = wishlist.items.any((item) => item.productId == widget.productId);
                              return ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await wishlist.toggleWishlist(
                                      productId: widget.productId,
                                      name: name,
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
                                icon: Icon(
                                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                                  color: isWishlisted ? Colors.red : Colors.white,
                                ),
                                label: Text(
                                  isWishlisted ? 'Wishlisted' : 'Add to Wishlist',
                                  style: TextStyle(
                                    color: isWishlisted ? Colors.red : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  backgroundColor: isWishlisted ? Colors.red.withOpacity(0.2) : Colors.grey[700],
                                  foregroundColor: isWishlisted ? Colors.red : Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  // Show wishlist message when out of stock
                  if (isOutOfStock && currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Add to wishlist to get notified when restocked!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[300],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildRatingSection() {
    final currentRating = widget.productData['rating'] != null
        ? (widget.productData['rating'] as num).toDouble()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFDD0),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStarDisplay(currentRating),
            const SizedBox(width: 8),
            Text(
              currentRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFF3E5AB),
              ),
            ),
          ],
        ),
        if (_isCheckingPurchase)
          const SizedBox(height: 16)
        else ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _hasPurchased ? _showReviewDialog : null,
            icon: const Icon(Icons.rate_review),
            label: const Text('Submit Review'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          if (!_hasPurchased && _currentUser != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Purchase this item to submit a review',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStarDisplay(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating == 0.0) {
          return const Icon(
            Icons.star_border,
            size: 20,
            color: Colors.amber,
          );
        }
        if (index < rating.floor()) {
          return const Icon(
            Icons.star,
            size: 20,
            color: Colors.amber,
          );
        } else if (index < rating.ceil() && rating % 1 != 0) {
          return const Icon(
            Icons.star_half,
            size: 20,
            color: Colors.amber,
          );
        } else {
          return const Icon(
            Icons.star_border,
            size: 20,
            color: Colors.amber,
          );
        }
      }),
    );
  }

  void _showReviewDialog() {
    final ratingController = TextEditingController();
    final reviewController = TextEditingController();
    double selectedRating = _userRating ?? 0.0;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Submit Review'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rating (1-5):'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starRating = index + 1.0;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = starRating;
                            });
                          },
                          child: Icon(
                            selectedRating >= starRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 32,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reviewController,
                      decoration: const InputDecoration(
                        labelText: 'Review',
                        hintText: 'Write your review here...',
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write a review';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        if (selectedRating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a rating')),
                          );
                          return;
                        }
                        setDialogState(() {
                          isLoading = true;
                        });
                        await _submitReview(
                            selectedRating, reviewController.text.trim());
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      ratingController.dispose();
      reviewController.dispose();
    });
  }

  Future<void> _submitReview(double rating, String reviewText) async {
    if (_currentUser == null || !_hasPurchased) return;

    try {
      final userId = _currentUser!.uid;

      // Save user's review with rating
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .doc(userId)
          .set({
        'rating': rating,
        'review': reviewText,
        'userId': userId,
        'userEmail': _currentUser!.email ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also save rating separately for average calculation
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('ratings')
          .doc(userId)
          .set({
        'rating': rating,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Calculate average rating
      final ratingsSnapshot = await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('ratings')
          .get();

      double totalRating = 0.0;
      int count = 0;
      for (var doc in ratingsSnapshot.docs) {
        final ratingValue = (doc.data()['rating'] as num?)?.toDouble();
        if (ratingValue != null) {
          totalRating += ratingValue;
          count++;
        }
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;

      // Update product's average rating
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .update({'rating': averageRating});

      setState(() {
        _userRating = rating;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }
}


