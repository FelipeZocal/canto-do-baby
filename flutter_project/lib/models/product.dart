class ProductModel {
  String? id;
  String name;
  String description;
  String date;
  String time;
  String observation;
  bool isAvailable;
  double price;
  int quantity;
  String? imageUrl;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.observation,
    this.isAvailable = true,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': date,
      'time': time,
      'observation': observation,
      'isAvailable': isAvailable,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      observation: map['observation'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }
}
