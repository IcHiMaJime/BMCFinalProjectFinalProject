// lib/providers/cart_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CartItem Model --- (No changes)
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

// --- CartProvider ---
class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  String? _userId;
  StreamSubscription? _authSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get userId => _userId;

  void initialize() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        _fetchCart();
      } else {
        _userId = null;
        _items.clear();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  int get totalQuantity {
    int total = 0;
    for (var item in _items) {
      total += item.quantity;
    }
    return total;
  }

  List<CartItem> get items => [..._items];

  // 1. RENAMED: 'totalAmount' is now 'subtotal' (Price before VAT)
  double get subtotal {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // 2. NEW GETTER: VAT (12% of subtotal)
  double get vat {
    return subtotal * 0.12;
  }

  // 3. NEW GETTER: Total Price with VAT
  double get totalPriceWithVat {
    return subtotal + vat;
  }

  // The rest of the functions are unchanged from Module 14, except placeOrder:
  void addItem(String id, String name, double price, int quantity) {
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
          id: id,
          name: name,
          price: price,
          quantity: quantity
      ));
    }

    _saveCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  // UPDATED: placeOrder to save price breakdown
  Future<void> placeOrder() async {
    if (_userId == null || _items.isEmpty) {
      throw Exception('Cannot place order: User not logged in or cart is empty.');
    }

    try {
      final List<Map<String, dynamic>> itemsMap =
      _items.map((item) => item.toJson()).toList();

      await _firestore.collection('orders').add({
        'userId': _userId,
        // SAVED NEW BREAKDOWN
        'subtotal': subtotal,
        'vat': vat,
        'totalPrice': totalPriceWithVat,
        'orderDate': Timestamp.now(),
        'items': itemsMap,
        'status': 'Pending',
      });

      await clearCart();
    } catch (e) {
      print('Error placing order: $e');
      rethrow;
    }
  }

  Future<void> _fetchCart() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore.collection('userCarts').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['cartItems'] is List) {
          final List<dynamic> cartItemsData = data['cartItems'];
          _items = cartItemsData
              .map((itemMap) => CartItem.fromJson(itemMap))
              .toList();
        } else {
          _items.clear();
        }
      } else {
        _items.clear();
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  Future<void> _saveCart() async {
    if (_userId == null) return;
    try {
      final List<Map<String, dynamic>> cartData =
      _items.map((item) => item.toJson()).toList();

      await _firestore.collection('userCarts').doc(_userId).set({
        'cartItems': cartData,
      });
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
}