import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import 'barcode_scanner_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _showProductDialog({Product? existingProduct}) {
    final nameController =
        TextEditingController(text: existingProduct?.name ?? '');
    final priceController = TextEditingController(
      text: existingProduct != null ? existingProduct.price.toStringAsFixed(0) : '',
    );
    final barcodeController =
        TextEditingController(text: existingProduct?.barcode ?? '');
    final visualLabelController =
        TextEditingController(text: existingProduct?.visualLabel ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingProduct == null ? 'Tambah Produk & Harga' : 'Ubah Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  hintText: 'Contoh: Indomie Goreng',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  hintText: 'Contoh: 3500',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Barcode',
                        hintText: 'Contoh: 899275321...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Scan Barcode Produk Langsung',
                    onPressed: () async {
                      // Buka scanner untuk mengambil kode barcode otomatis
                      final scanned = await Navigator.push<Product>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerScreen(),
                        ),
                      );
                      if (scanned != null) {
                        barcodeController.text = scanned.barcode;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: visualLabelController,
                decoration: const InputDecoration(
                  labelText: 'Label Visual AI (Opsional)',
                  hintText: 'Nama label di file labels.txt model AI',
                  border: OutlineInputBorder(),
                  helperText: 'Digunakan saat scan kamera foto produk',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();
              final barcode = barcodeController.text.trim();
              final visualLabel = visualLabelController.text.trim();

              if (name.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan Harga wajib diisi!')),
                );
                return;
              }

              final price = double.tryParse(priceText) ?? 0.0;

              final product = Product(
                id: existingProduct?.id ?? '',
                name: name,
                price: price,
                barcode: barcode,
                visualLabel: visualLabel,
              );

              await _firestoreService.saveProduct(product);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await _firestoreService.deleteProduct(product.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Produk & Harga'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
        onPressed: () => _showProductDialog(),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _firestoreService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada produk tersimpan di Cloud Firestore.\nTekan tombol + Tambah Produk di bawah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = products[index];
              return ListTile(
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga: ${_currencyFormat.format(item.price)}'),
                    if (item.barcode.isNotEmpty)
                      Text(
                        'Barcode: ${item.barcode}',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    if (item.visualLabel.isNotEmpty)
                      Text(
                        'Visual AI: ${item.visualLabel}',
                        style: const TextStyle(fontSize: 12, color: Colors.teal),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showProductDialog(existingProduct: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(item),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
