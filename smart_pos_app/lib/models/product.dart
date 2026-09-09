class Product {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final String visualLabel;
  final String imageUrl;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    this.visualLabel = '',
    this.imageUrl = '',
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      barcode: data['barcode'] as String? ?? '',
      name: data['name'] as String? ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      visualLabel: data['visualLabel'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'price': price,
      'visualLabel': visualLabel,
      'imageUrl': imageUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
