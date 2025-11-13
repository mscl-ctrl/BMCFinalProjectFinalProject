import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int stock;
  final DateTime addedAt;

  WishlistItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['productId'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      stock: json['stock'] ?? 0,
      addedAt: (json['addedAt'] as Timestamp).toDate(),
    );
  }
}

class WishlistProvider with ChangeNotifier {
  List<WishlistItem> _items = [];
  String? _userId;
  StreamSubscription? _authSubscription;
  StreamSubscription? _wishlistSubscription;
  final Map<String, StreamSubscription> _productStockSubscriptions = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<WishlistItem> get items => _items;
  int get itemCount => _items.length;

  WishlistProvider() {
    if (kDebugMode) {
      print('WishlistProvider created.');
    }
  }

  void initializeAuthListener() {
    if (kDebugMode) {
      print('WishlistProvider auth listener initialized');
    }
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        if (kDebugMode) {
          print('User logged out, clearing wishlist.');
        }
        _userId = null;
        _items = [];
        _wishlistSubscription?.cancel();
        _cancelAllProductStockSubscriptions();
      } else {
        if (kDebugMode) {
          print('User logged in: ${user.uid}. Fetching wishlist...');
        }
        _userId = user.uid;
        _fetchWishlist();
      }
      notifyListeners();
    });
  }

  Future<void> _fetchWishlist() async {
    if (_userId == null) return;

    try {
      _wishlistSubscription?.cancel();
      _wishlistSubscription = _firestore
          .collection('wishlists')
          .doc(_userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data()!['items'] != null) {
          final List<dynamic> wishlistData = snapshot.data()!['items'];
          _items = wishlistData
              .map((item) => WishlistItem.fromJson(item))
              .toList();
          if (kDebugMode) {
            print('Wishlist fetched successfully: ${_items.length} items');
          }
          // Monitor stock changes for all wishlisted products
          _monitorProductStock();
        } else {
          _items = [];
          _cancelAllProductStockSubscriptions();
        }
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching wishlist: $e');
      }
      _items = [];
      notifyListeners();
    }
  }

  Future<void> _saveWishlist() async {
    if (_userId == null) return;

    try {
      final List<Map<String, dynamic>> wishlistData =
          _items.map((item) => item.toJson()).toList();

      await _firestore.collection('wishlists').doc(_userId).set({
        'items': wishlistData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('Wishlist saved to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving wishlist: $e');
      }
    }
  }

  Future<bool> isWishlisted(String productId) async {
    return _items.any((item) => item.productId == productId);
  }

  Future<void> addToWishlist({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required int stock,
  }) async {
    if (_userId == null) {
      throw Exception('User must be logged in to add to wishlist');
    }

    // Check if already in wishlist
    if (_items.any((item) => item.productId == productId)) {
      return; // Already in wishlist
    }

    _items.add(WishlistItem(
      productId: productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      stock: stock,
      addedAt: DateTime.now(),
    ));

    await _saveWishlist();
    _monitorProductStock(); // Start monitoring this new product
    notifyListeners();
  }

  Future<void> removeFromWishlist(String productId) async {
    if (_userId == null) return;

    _items.removeWhere((item) => item.productId == productId);
    // Cancel subscription for this product
    _productStockSubscriptions[productId]?.cancel();
    _productStockSubscriptions.remove(productId);
    await _saveWishlist();
    notifyListeners();
  }

  Future<void> toggleWishlist({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required int stock,
  }) async {
    final isInWishlist = _items.any((item) => item.productId == productId);
    if (isInWishlist) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        stock: stock,
      );
    }
  }

  void _monitorProductStock() {
    if (_userId == null) return;

    // Cancel old subscriptions for products no longer in wishlist
    final currentProductIds = _items.map((item) => item.productId).toSet();
    _productStockSubscriptions.removeWhere((productId, subscription) {
      if (!currentProductIds.contains(productId)) {
        subscription.cancel();
        return true;
      }
      return false;
    });

    // Monitor all wishlisted products for stock changes
    if (_items.isEmpty) return;

    for (var item in _items) {
      // Skip if already monitoring this product
      if (_productStockSubscriptions.containsKey(item.productId)) continue;

      final subscription = _firestore
          .collection('products')
          .doc(item.productId)
          .snapshots()
          .listen((productSnapshot) {
        if (!productSnapshot.exists) return;

        final productData = productSnapshot.data();
        if (productData == null) return;

        final currentStock = productData['stock'] ?? 0;
        final previousStock = item.stock;

        // If product was out of stock (0) and now has stock (>0), notify user
        if (previousStock == 0 && currentStock > 0) {
          _notifyProductRestocked(item.productId, item.name);
        }

        // Update the stock in wishlist item if it changed
        if (currentStock != previousStock) {
          final index = _items.indexWhere((i) => i.productId == item.productId);
          if (index != -1) {
            _items[index] = WishlistItem(
              productId: item.productId,
              name: item.name,
              price: item.price,
              imageUrl: item.imageUrl,
              stock: currentStock,
              addedAt: item.addedAt,
            );
            _saveWishlist();
            notifyListeners();
          }
        }
      });

      _productStockSubscriptions[item.productId] = subscription;
    }
  }

  void _cancelAllProductStockSubscriptions() {
    for (var subscription in _productStockSubscriptions.values) {
      subscription.cancel();
    }
    _productStockSubscriptions.clear();
  }

  Future<void> _notifyProductRestocked(String productId, String productName) async {
    if (_userId == null) return;

    try {
      // Create a notification in the notifications collection
      await _firestore.collection('notifications').add({
        'userId': _userId,
        'type': 'product_restocked',
        'title': 'Product Restocked!',
        'message': '$productName is now back in stock!',
        'productId': productId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('Restock notification created for $productName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating restock notification: $e');
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _wishlistSubscription?.cancel();
    _cancelAllProductStockSubscriptions();
    super.dispose();
  }
}
