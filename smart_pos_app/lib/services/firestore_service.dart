import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');

  // Stream semua produk untuk sinkronisasi real-time antar perangkat
  Stream<List<Product>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Cari produk berdasarkan Barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final query = await _productsRef
        .where('barcode', isEqualTo: barcode.trim())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Cari produk berdasarkan Label Visual AI (Image Classification)
  Future<Product?> getProductByVisualLabel(String label) async {
    final query = await _productsRef
        .where('visualLabel', isEqualTo: label.trim())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Tambah atau perbarui produk
  Future<void> saveProduct(Product product) async {
    if (product.id.isEmpty) {
      await _productsRef.add(product.toMap());
    } else {
      await _productsRef.doc(product.id).set(
            product.toMap(),
            SetOptions(merge: true),
          );
    }
  }

  // Hapus produk
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }
}
