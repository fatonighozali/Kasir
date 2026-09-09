import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../services/visual_recognition_service.dart';

class VisualScannerScreen extends StatefulWidget {
  const VisualScannerScreen({super.key});

  @override
  State<VisualScannerScreen> createState() => _VisualScannerScreenState();
}

class _VisualScannerScreenState extends State<VisualScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final VisualRecognitionService _aiService = VisualRecognitionService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isCameraReady = false;
  bool _isProcessing = false;
  String _statusText = 'Arahkan kamera ke produk';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _aiService.loadModel();
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Inisialisasi kamera / model gagal: $e';
        });
      }
    }
  }

  Future<void> _captureAndClassify() async {
    if (!_isCameraReady || _cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Menganalisis gambar dengan AI...';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      final result = await _aiService.classifyImage(imageFile);

      if (result == null || result.confidence < 0.60) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Produk Tidak Dikenali'),
            content: Text(
              result == null
                  ? 'Model AI belum dimuat atau tidak mendeteksi objek.'
                  : 'Keyakinan deteksi rendah (${(result.confidence * 100).toStringAsFixed(1)}%). Pastikan pencahayaan cukup dan objek berada di tengah.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
        setState(() {
          _isProcessing = false;
          _statusText = 'Arahkan kamera ke produk';
        });
        return;
      }

      // Cari produk di Firestore dengan visualLabel yang cocok
      final product = await _firestoreService.getProductByVisualLabel(result.label);

      if (!mounted) return;

      if (product != null) {
        // Tampilkan konfirmasi hasil deteksi
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Produk Terdeteksi!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nama: ${product.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Tingkat Akurasi AI: ${(result.confidence * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 4),
                Text('Harga: Rp ${product.price.toStringAsFixed(0)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Bukan Ini'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tambah ke Keranjang'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          Navigator.pop(context, product);
          return;
        }
      } else {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Label Dikenali, Harga Belum Ada'),
            content: Text(
              'AI mengenali objek sebagai "${result.label}", namun data harga untuk label ini belum didaftarkan di menu Kelola Produk.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Arahkan kamera ke produk';
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Visual Produk (AI)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Guide overlay kotak bidik foto
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.tealAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Bar petunjuk di atas
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),

          // Tombol Shutter Capture
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                onPressed: _isProcessing ? null : _captureAndClassify,
                icon: const Icon(Icons.camera),
                label: Text(_isProcessing ? 'Memproses...' : 'Ambil Foto & Kenali'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
