// lib/screens/home_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:gourmet_snacks_app/providers/cart_provider.dart';

import 'package:gourmet_snacks_app/widgets/product_card.dart';
import 'package:gourmet_snacks_app/screens/product_detail_screen.dart';
import 'package:gourmet_snacks_app/screens/admin/admin_panel_screen.dart';
import 'package:gourmet_snacks_app/screens/cart_screen.dart';
import 'package:gourmet_snacks_app/screens/order_history_screen.dart';
import 'package:gourmet_snacks_app/screens/profile_screen.dart';
import 'package:gourmet_snacks_app/widgets/notification_icon.dart';
import 'package:gourmet_snacks_app/screens/chat_screen.dart';
import 'package:gourmet_snacks_app/main.dart'; // Import for kBlue and kLightBackground
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userRole;
  bool _isLoadingRole = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ STATE PARA SA SEARCH AT FILTER
  String _searchText = '';
  // Default sa 'All', options: 'Snacks', 'Drinks', 'All'
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
    });
  }

  Future<void> _fetchUserRole() async {
    final currentUser = _auth.currentUser;
    // ... (rest of _fetchUserRole function remains the same)
    if (currentUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'];
            _isLoadingRole = false;
          });
        } else {
          setState(() {
            _userRole = 'customer';
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        print('Error fetching user role: $e');
        setState(() {
          _userRole = 'customer';
          _isLoadingRole = false;
        });
      }
    } else {
      setState(() {
        _userRole = null;
        _isLoadingRole = false;
      });
    }
  }

  Stream<QuerySnapshot> _fetchProductsStream() {
    // Kukunin ang lahat ng products stream
    return _firestore.collection('products').snapshots();
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        // ✅ LEFT-ALIGNED TITLE
        title: Text(
          'Gourmet Snacks Marketplace',
          style: GoogleFonts.poppins(
            fontSize: 15, // NEW: Mas maliit na size
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        centerTitle: false, // Ensures the title is left-aligned
        actions: [
          // 🛒 Cart Icon with Badge
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge.count(
              count: cart.totalQuantity,
              isLabelVisible: cart.totalQuantity > 0,
              smallSize: 20,
              textColor: Colors.white,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Your Cart',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          const NotificationIcon(),

          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'My Orders',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),

          if (_userRole == 'admin' && !_isLoadingRole)
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

          if (currentUser != null)
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

      // 🛍️ Main Content
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Today\'s Snacks',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ),

            // ✅ SEARCH AND FILTER SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for snacks...',
                        prefixIcon: const Icon(Icons.search, color: kBlue),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                        isDense: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Category Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        icon: const Icon(Icons.arrow_drop_down, color: kBlue),
                        style: GoogleFonts.lato(color: Colors.black, fontSize: 15),
                        items: <String>['All', 'Snacks', 'Drinks']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(fontWeight: value == _selectedCategory ? FontWeight.bold : FontWeight.normal)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // END OF SEARCH AND FILTER SECTION


            // 🧁 Product Grid
            StreamBuilder<QuerySnapshot>(
              stream: _fetchProductsStream(), // Gamitin ang bagong function
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }

                // Kukunin ang lahat ng documents
                final allProductDocs = snapshot.data!.docs;

                // ✅ CLIENT-SIDE FILTERING LOGIC
                final filteredProductDocs = allProductDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  // Tiyakin na ang category field ay naglalaman ng 'Snacks' o 'Drinks'
                  final category = (data['category'] as String? ?? 'snacks').toLowerCase();

                  // 1. Search Filter (Case-insensitive check)
                  final matchesSearch = _searchText.isEmpty || name.contains(_searchText.toLowerCase());

                  // 2. Category Filter
                  final matchesCategory = _selectedCategory == 'All' ||
                      category == _selectedCategory.toLowerCase();

                  return matchesSearch && matchesCategory;
                }).toList();
                // END OF CLIENT-SIDE FILTERING LOGIC


                if (filteredProductDocs.isEmpty && _searchText.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No snacks found matching "$_searchText" in ${_selectedCategory == 'All' ? 'all categories' : _selectedCategory}.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                if (filteredProductDocs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No products available right now.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }


                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredProductDocs.length,
                  itemBuilder: (context, index) {
                    final productDoc = filteredProductDocs[index];
                    final productData = productDoc.data() as Map<String, dynamic>;

                    return ProductCard(
                      productName: productData['name'] ?? 'No Name',
                      price: (productData['price'] as num?)?.toDouble() ?? 0.0,
                      imageUrl: productData['imageUrl'] ?? '',
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
          ],
        ),
      ),

      // Floating Action Button for Chat
      floatingActionButton: _userRole == 'customer' && currentUser != null
          ? StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('chats')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] ?? 0;
            }
          }
          return Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: FloatingActionButton.extended(
              backgroundColor: kLightBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: currentUser.uid,
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : null,
    );
  }
}