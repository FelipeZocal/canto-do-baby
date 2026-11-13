import 'product.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;

  // Transforma o item em Map para salvar no Firestore/MockAPI
  Map<String, dynamic> toMap() {
    var prodMap = product.toMap();
    prodMap['id'] = product.id; // Garante que o ID vai junto
    return {
      'product': prodMap,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      product: ProductModel.fromMap(map['product'], map['product']['id'] ?? ''),
      quantity: map['quantity'] ?? 1,
    );
  }
}