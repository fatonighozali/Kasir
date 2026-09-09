# Smart POS Kasir (Flutter + Barcode Scanner + Visual AI + Cloud Firestore)

Aplikasi kasir (Point of Sale) mobile berbasis **Flutter** yang dilengkapi dengan:
1. **Pindai Barcode / QR Code**: Membaca barcode kemasan secara instan via kamera (`mobile_scanner`).
2. **Scan Pengenalan Gambar Produk (Visual AI)**: Mengidentifikasi produk berdasarkan foto fisik kemasan menggunakan model **TensorFlow Lite (`tflite_flutter`)**.
3. **Database Cloud Realtime (Firebase Firestore)**: Data master produk dan harga tersinkronisasi otomatis antar-perangkat smartphone.
4. **Kalkulasi Otomatis Total Belanja**: Menghitung kuantitas, subtotal, dan total pembayaran secara real-time.

---

## 📁 Struktur Direktori Proyek

```
smart_pos_app/
├── android/
│   └── app/src/main/AndroidManifest.xml   # Izin Kamera & Internet Android
├── assets/
│   └── models/
│       ├── labels.txt                     # Daftar nama label kelas AI
│       └── model.tflite                   # File model TensorFlow Lite
├── lib/
│   ├── main.dart                          # Inisialisasi Firebase & App Entry
│   ├── models/
│   │   ├── product.dart                   # Data Model Produk
│   │   └── cart_item.dart                 # Data Model Keranjang Belanja
│   ├── services/
│   │   ├── firestore_service.dart         # Sinkronisasi Cloud Firestore
│   │   └── visual_recognition_service.dart# Mesin Inferensi Visual AI (TFLite)
│   └── screens/
│       ├── pos_home_screen.dart           # Layar Utama Kasir & Keranjang
│       ├── barcode_scanner_screen.dart    # Layar Pemindai Barcode
│       ├── visual_scanner_screen.dart     # Layar Kamera Pengenal Foto Produk
│       └── product_management_screen.dart # Layar Kelola Master Produk & Harga
└── pubspec.yaml                           # Dependensi & Aset
```

---

## 🚀 Panduan Setup & Build APK

### 1. Prasyarat
- Flutter SDK (versi >= 3.2.0)
- Android Studio / Android SDK
- Akun Firebase Console

### 2. Setup Firebase
1. Buka [Firebase Console](https://console.firebase.google.com/).
2. Buat proyek baru dan aktifkan **Cloud Firestore Database** (mode pengujian / test mode atau set security rules).
3. Daftarkan aplikasi Android dengan package name: `com.example.smart_pos_app`.
4. Unduh file `google-services.json` dan letakkan di folder:
   `smart_pos_app/android/app/google-services.json`

### 3. Setup Model Visual AI (Pengenalan Foto Produk)
Untuk melatih AI mengenali kemasan produk toko Anda:
1. Kunjungi [Google Teachable Machine](https://teachablemachine.withgoogle.com/train/image).
2. Buat kelas untuk setiap produk (contoh: "Indomie Goreng", "Aqua 600ml", dll). Ambil 30–50 foto untuk masing-masing produk dari berbagai sudut.
3. Klik **Train Model**.
4. Klik **Export Model** -> pilih tab **TensorFlow Lite** -> format **Floating point** -> Unduh.
5. Ekstrak file hasil unduhan:
   - Gantikan `assets/models/model.tflite` dengan file model Anda.
   - Gantikan isi `assets/models/labels.txt` dengan daftar label produk Anda.

### 4. Menjalankan & Build File APK
Jalankan perintah berikut di terminal:

```bash
# 1. Unduh dependensi
flutter pub get

# 2. Uji coba langsung di HP Android via kabel USB / Debugger
flutter run

# 3. Build file APK siap instal (Release)
flutter build apk --release
```

File APK siap pakai akan berada di:
`build/app/outputs/flutter-apk/app-release.apk`
