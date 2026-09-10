import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'products';

  // CREATE / UPDATE
  Future<void> saveProduct(ProductModel product) async {
    if (product.id == null || product.id!.isEmpty) {
      // Cria novo documento com ID automático
      await _db.collection(collectionPath).add(product.toMap());
    } else {
      // Atualiza documento existente
      await _db
          .collection(collectionPath)
          .doc(product.id)
          .update(product.toMap());
    }
  }

  // READ (Retorna um Stream para atualizar a tela em tempo real)
  Stream<List<ProductModel>> getProducts() {
    return _db
        .collection(collectionPath)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // DELETE
  Future<void> deleteProduct(String id) async {
    await _db.collection(collectionPath).doc(id).delete();
  }
}
