import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/providers/wishlist_provider.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:ecommerce_app/screens/category_screen.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/profile_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:ecommerce_app/screens/wishlist_screen.dart';
import 'package:ecommerce_app/widgets/notification_icon.dart'; // 1. ADD THIS
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ADD THIS LINE
  final CarouselSliderController _carouselController = CarouselSliderController();
  
  // Carousel images
  final List<String> carouselImages = [
    'https://scontent.fmnl8-1.fna.fbcdn.net/v/t39.30808-6/474973491_122218937264158538_7006585381753728470_n.jpg?_nc_cat=106&ccb=1-7&_nc_sid=cc71e4&_nc_eui2=AeHgg9yKaHuatLv2Z1e2iIDoiDqqDce5qqWIOqoNx7mqpfxplSulGsHQ6n5WH4thlWA-cc10Suz5sfiVbJDUY7hB&_nc_ohc=BinQJOIA4t0Q7kNvwEYG5m8&_nc_oc=Admcfpc2Qv_4gnWpAXCjXWwwqYO1cuaGSDGT3AjjLx1l4uKoOdX0WzKXiEqMhawPo-U&_nc_zt=23&_nc_ht=scontent.fmnl8-1.fna&_nc_gid=07n10pH_hwA-l-EH5yqtfA&oh=00_Afh_xHgHj1OiGQRi6967uaYWraF9jYBnGMmcKjTpfk9Lig&oe=691AE4CE',
    'https://scontent.fmnl8-4.fna.fbcdn.net/v/t39.30808-6/547104324_122266615826158538_8685520999580796923_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=127cfc&_nc_eui2=AeFKtTWTNTmRpep-OVihqRlN4GtjW6kl0ELga2NbqSXQQkZlC8Vcqn10alAwbUB9VgF9lXVGAOzJr6PSbBcjvyKH&_nc_ohc=JRxsRvqaYMAQ7kNvwEqsZXb&_nc_oc=AdkXxysQR2bXBe6WMSB1BcI9FsRIrQ-iuOhJbu9vvX-9McOF68jjY21gHs2XFaMOpcM&_nc_zt=23&_nc_ht=scontent.fmnl8-4.fna&_nc_gid=4E2pYIg57Xt93ySxc1ubWQ&oh=00_AfjUR5bJ-qtgUbvJxTx0wwdVFJpC42KC4G_nb7K9NjQetg&oe=691ADED0',
    'https://scontent.fmnl8-3.fna.fbcdn.net/v/t39.30808-6/546847474_122266615634158538_2192912672214825380_n.jpg?_nc_cat=105&ccb=1-7&_nc_sid=127cfc&_nc_eui2=AeGOula3pV_xxw6b8FPZdHs6IAZHA96_pbogBkcD3r-lur8sNCpLhZjmgfsMyz_U-qkPWENRDGZIv5fSPbH2oIaF&_nc_ohc=TmiCjMO6lpMQ7kNvwGceCBx&_nc_oc=AdlgJiN_v5ZfhkauSwrTtfGKS8yvKZ9DSV2WwSRSV54hW625o_RVumYI47JSFqLVW7c&_nc_zt=23&_nc_ht=scontent.fmnl8-3.fna&_nc_gid=wpLR2MSGZP0vbIdzwns-tQ&oh=00_AfjwYA_lpbwEDkiuWWPSKUSyRnWS8Z7ygf65bOiwW1E1zA&oe=691B0031',
    'https://scontent.fmnl8-4.fna.fbcdn.net/v/t39.30808-6/547377619_122266616246158538_8849140219671123150_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=127cfc&_nc_eui2=AeGhqZakhJa0jdD7MH_gSCJMIVhlPbRyz2EhWGU9tHLPYbR1bpGaD3ptZTBXga8JmO5kdUdqxpuvsx3tGf6AnMnF&_nc_ohc=2ff6NxXGk7cQ7kNvwEhtNBL&_nc_oc=AdklwWjPDcrIUA57O0onyXt08EvgezCQDI38C8LoV9vBc-78vsDaUi5smQrc7_kNgTs&_nc_zt=23&_nc_ht=scontent.fmnl8-4.fna&_nc_gid=foXWBjPM4TmXMg--QmlkeQ&oh=00_AfjOqsR79nbL58I2j7meEQQ9a90gQCAe0WTOyuWt3u-QXA&oe=691ACEA4',
    'https://scontent.fmnl8-1.fna.fbcdn.net/v/t39.30808-6/547314496_122266616174158538_6316020441009716676_n.jpg?_nc_cat=106&ccb=1-7&_nc_sid=127cfc&_nc_eui2=AeGBul3FnsxAF-uNfaC-zGk_4DJ7l-TRB3rgMnuX5NEHegw09WyA9j4E5NpE1oLqPW__6wZpBiGMgNYuw1C4rWSk&_nc_ohc=b0wFDstW7vUQ7kNvwG84jcb&_nc_oc=AdnT2m2ZEmT8yIxIAqho8ety-E1Pj5z5Mxfj41WhxjxrrSd8upyP9l-_gqP597Jojgo&_nc_zt=23&_nc_ht=scontent.fmnl8-1.fna&_nc_gid=inWWICtMsY1ooxX06xWkJg&oh=00_Afj_ZrEA3hg0-GhFgfAN786BDDDTsF0C2ut56-Il2k5dNQ&oe=691AE920',
  ];


  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = (doc.data()!['role'] ?? 'user') as String;
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }


  // Categories list
  final List<Map<String, dynamic>> categories = [
    {'name': 'Laptops', 'icon': Icons.laptop},
    {'name': 'Motherboard', 'icon': Icons.memory},
    {'name': 'Processor (CPU)', 'icon': Icons.speed},
    {'name': 'Graphics Card (GPU)', 'icon': Icons.videogame_asset},
    {'name': 'Memory Sticks (RAM)', 'icon': Icons.storage},
    {'name': 'Storage Devices', 'icon': Icons.save},
    {'name': 'Power Supply Unit (PSU)', 'icon': Icons.power},
    {'name': 'Chassis', 'icon': Icons.computer},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF425A87), // Dark blue
                Color(0xFF397DED), // Bright blue
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: _currentUser?.email != null
                          ? Text(
                              _currentUser!.email![0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF425A87),
                              ),
                            )
                          : const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentUser?.email ?? 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...categories.map((category) {
                return ListTile(
                  leading: Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                  ),
                  title: Text(
                    category['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(
                          categoryName: category['name']!,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
              const Divider(color: Colors.white70),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text(
                  'Home',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text(
                  'Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white, // White icons on gradient background
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
        // 1. --- THIS IS THE CHANGE ---
        //    DELETE your old title:
        /*
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser.email}' : 'Home'),
        */
        // 2. ADD this new title:
        title: Image.asset(
          'assets/images/app_logo.png', // 3. The path to your logo
          height: 50, // 4. Increased height for nav bar
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        // 5. 'centerTitle' is now set to true
        
        // --- END OF CHANGE ---
        actions: [
          // 1. Wishlist Icon
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              return Badge(
                label: Text(wishlist.itemCount.toString()),
                isLabelVisible: wishlist.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.favorite),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const WishlistScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // 2. Cart Icon (Unchanged)
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // 3. --- ADD OUR NEW WIDGET ---
          const NotificationIcon(),
          // --- END OF NEW WIDGET ---
          
          // 3. "My Orders" Icon (Unchanged)
          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          
          // 3. Your existing Admin Icon (if admin)
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
          
          // 4. --- THIS IS THE CHANGE ---
          //    DELETE the old "Logout" IconButton
          /*
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut, // We are deleting this
          ),
          */

          // 5. ADD this new "Profile" IconButton
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return CustomScrollView(
              slivers: [
                // Carousel Section
                SliverToBoxAdapter(
                  child: CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: carouselImages.length,
                    itemBuilder: (context, index, realIndex) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            carouselImages[index],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.grey),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 400.0,
                      viewportFraction: 1.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: false,
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 8.0),
                ),
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No products found. Add some in the Admin Panel!'),
                    ),
                  ),
                ),
              ],
            );
          }
          final products = snapshot.data!.docs;
          // Responsive grid based on screen width
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 1);
          final childAspectRatio = screenWidth > 600 ? 0.75 : (screenWidth > 400 ? 0.7 : 0.85);
          
          return CustomScrollView(
            slivers: [
              // Carousel Section
              SliverToBoxAdapter(
                child: CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: carouselImages.length,
                  itemBuilder: (context, index, realIndex) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.transparent,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          carouselImages[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.grey),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 400.0,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enlargeCenterPage: false,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8.0),
              ),
              // Products Grid Section
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: products.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // 1. --- REPLACE YOUR 'floatingActionButton:' ---
      floatingActionButton: _userRole == 'user' && _currentUser != null
          ? StreamBuilder<DocumentSnapshot>( // 2. A new StreamBuilder
              // 3. Listen to *this user's* chat document
              stream: _firestore.collection('chats').doc(_currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                
                int unreadCount = 0;
                // 4. Check if the doc exists and has our count field
                if (snapshot.hasData && snapshot.data!.exists) {
                  // Ensure data is not null before casting
                  final data = snapshot.data!.data();
                  if (data != null) {
                    unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] ?? 0;
                  }
                }
       
                // 5. --- THE FIX for "trailing not defined" ---
                //    We wrap the FAB in the Badge widget
                return Badge(
                  // 6. Show the count in the badge
                  label: Text('$unreadCount'),
                  // 7. Only show the badge if the count is > 0
                  isLabelVisible: unreadCount > 0,
                  // 8. The FAB is now the *child* of the Badge
                  child: FloatingActionButton.extended(
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Admin'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: _currentUser.uid,
                          ),
                        ),
                      );
                    },
                  ),
                );
                // --- END OF FIX ---
              },
            )
          : null, // 9. If admin, don't show the FAB
    );
  }
}


