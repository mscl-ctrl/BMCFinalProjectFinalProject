import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/widgets/order_card.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
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
      // Check if the user is logged in
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E3B49),
              Color(0xFF1E1B52),
            ],
          ),
        ),
        child: user == null
            ? const Center(
                child: Text(
                  'Please log in to see your orders.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            // If logged in, show the StreamBuilder
            : StreamBuilder<QuerySnapshot>(
                // Query without orderBy to avoid index requirement
                // We'll sort in memory instead
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                
                builder: (context, snapshot) {
                  // Handle loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                  
                  // Handle error state with better error message
                  if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    final hasIndexError = error.contains('index') || error.contains('Index');
                    
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasIndexError
                                  ? 'Firestore Index Required'
                                  : 'Error loading orders',
                              style: const TextStyle(
                                color: Colors.white,
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
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Handle no data (no orders)
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You have not placed any orders yet.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // We have data! Get the list of order documents
                  final orderDocs = snapshot.data!.docs;
                  
                  // Sort in memory by createdAt (newest first)
                  orderDocs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['createdAt'] as Timestamp?;
                    final bTime = bData['createdAt'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime); // Descending order
                  });

                  // Use ListView.builder to show the list
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: orderDocs.length,
                    itemBuilder: (context, index) {
                      // Get the data for a single order
                      final orderData = orderDocs[index].data() as Map<String, dynamic>;
                      
                      // Return our custom OrderCard widget
                      return OrderCard(orderData: orderData);
                    },
                  );
                },
              ),
      ),
    );
  }
}

