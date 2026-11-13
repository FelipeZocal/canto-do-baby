import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  // Padrão Singleton
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  CartService._internal() {
    // Fica escutando: se o usuário logar, carrega o carrinho salvo dele no Firestore
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadCartFromFirestore(user.uid);
      } else {
        _clearCartLocal();
      }
    });
  }

  List<CartItemModel> _items = [];
  double _shippingCost = 0.0;
  double _discount = 0.0;

  List<CartItemModel> get items => _items;
  double get shippingCost => _shippingCost;
  double get discount => _discount;
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get total => (subtotal + _shippingCost) - _discount;

  // Pega a referência do carrinho do usuário logado no Firestore
  DocumentReference? get _userCartRef {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc('active_cart');
  }

  // --- MÉTODOS DO FIRESTORE ---

  Future<void> _loadCartFromFirestore(String uid) async {
    // 1. ESVAZIA A MEMÓRIA LOCAL PRIMEIRO (Garante que um usuário não veja o do outro)
    _items.clear();
    _shippingCost = 0.0;
    _discount = 0.0;

    try {
      final doc = await _userCartRef!.get();
      
      // 2. Se o usuário tiver um carrinho salvo no banco, carrega os itens
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> itemsData = data['items'] ?? [];
        _items = itemsData.map((e) => CartItemModel.fromMap(e)).toList();
      }
      
      // 3. Notifica o aplicativo (se for usuário novo, atualizará com o carrinho vazio)
      notifyListeners();
      
    } catch (e) {
      debugPrint("Erro ao carregar carrinho: $e");
    }
  }

  Future<void> _saveCartToFirestore() async {
    if (_userCartRef == null) return;
    try {
      final List<Map<String, dynamic>> itemsData = _items.map((e) => e.toMap()).toList();
      await _userCartRef!.set({'items': itemsData});
    } catch (e) {
      debugPrint("Erro ao salvar carrinho: $e");
    }
  }

  // --- MÉTODOS LOCAIS (que disparam o salvamento no Firestore) ---

  void addItem(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItemModel(product: product));
    }
    _saveCartToFirestore();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _saveCartToFirestore();
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCartToFirestore();
    notifyListeners();
  }

  void applyCoupon(String code) {
    if (code.trim().toUpperCase() == 'BABY10') {
      _discount = subtotal * 0.10;
    } else {
      _discount = 0.0;
      throw Exception('Cupom inválido');
    }
    notifyListeners();
  }

  void calculateShipping(String cep) {
    String cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length == 8) {
      _shippingCost = cleanCep.startsWith('15') ? 15.00 : 35.50;
      notifyListeners();
    } else {
      throw Exception('CEP inválido');
    }
  }

  void _clearCartLocal() {
    _items.clear();
    _shippingCost = 0.0;
    _discount = 0.0;
    notifyListeners();
  }

  Future<void> finalizarPedido() async {
    if (_items.isEmpty) throw Exception("O carrinho está vazio");
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final pedidoData = {
      'userId': userId,
      'data': DateTime.now().toIso8601String(),
      'subtotal': subtotal,
      'frete': _shippingCost,
      'desconto': _discount,
      'total': total,
      'itens': _items.map((e) => e.toMap()).toList(),
      'status': 'Processando'
    };

    try {
      final url = 'https://6ad60d62f71f154ac486615f.mockapi.io/api/v1/carrinho';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pedidoData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _clearCartLocal();
        if (_userCartRef != null) {
          await _userCartRef!.delete();
        }
      } else {
        throw Exception("Erro na API ao finalizar pedido. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Falha de conexão ao finalizar pedido: $e");
    }
  }
}