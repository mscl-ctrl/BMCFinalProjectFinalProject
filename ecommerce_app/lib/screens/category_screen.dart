import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryName;
  
  const CategoryScreen({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Text(categoryName),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            final hasIndexError = error.contains('index');
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFDFC5FE),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      hasIndexError
                          ? 'Firestore Index Required'
                          : 'Error loading products',
                      style: const TextStyle(
                        color: Color(0xFFDFC5FE),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasIndexError
                          ? 'Please create the required index in Firebase Console.\nThe link is in the error details below.'
                          : error,
                      style: const TextStyle(
                        color: Color(0xFFDFC5FE),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasIndexError) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Try again after user creates index
                          Navigator.of(context).pop();
                        },
                        child: const Text('Go Back'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No products found in $categoryName category.',
                style: const TextStyle(color: Color(0xFFDFC5FE)),
              ),
            );
          }
          final products = snapshot.data!.docs;
          // Sort products by createdAt in memory (since we removed orderBy to avoid index requirement)
          products.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // Descending order
          });
          
          // Responsive grid based on screen width
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 1);
          final childAspectRatio = screenWidth > 600 ? 0.75 : (screenWidth > 400 ? 0.7 : 0.85);
          
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;
              return ProductCard(
                productName: productData['name'],
                price: (productData['price'] as num).toDouble(),
                imageUrl: productData['imageUrl'],
                rating: productData['rating'] != null 
                    ? (productData['rating'] as num).toDouble() 
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productData: productData,
                        productId: productDoc.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

