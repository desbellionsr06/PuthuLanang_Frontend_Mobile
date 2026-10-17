# 📱 Puthu Lanang - Mobile App (Flutter)

Repositori ini berisi aplikasi pelanggan Puthu Lanang berbasis mobile. 
⚠️ **Syarat Utama:** Pastikan repositori **Backend** sudah dijalankan terlebih dahulu di Port 5000 agar aplikasi bisa terhubung ke database.

## 🚀 Cara Setup & Menjalankan (Lokal)

**1. Clone Repositori**
Buka terminal baru dan jalankan perintah berikut:
```bash
git clone [https://github.com/desbellionsr06/PuthuLanang_Frontend_Mobile.git](https://github.com/desbellionsr06/PuthuLanang_Frontend_Mobile.git)
```
**2. Masuk ke Folder Proyek**
Pastikan terminal Anda masuk ke lokasi yang terdapat file pubspec.yaml:
```bash
cd PuthuLanang_Frontend_Mobile

# CATATAN: Jika setelah di-clone file pubspec.yaml berada di dalam folder lagi, silakan 'cd' sekali lagi ke folder tersebut sebelum lanjut ke langkah 3.
```
**3. Instal Dependencies**
```Bash
flutter pub get
```
**4. Pengecekan URL API (Opsional)**

Pastikan URL konfigurasi API (biasanya di file api_service.dart) diarahkan ke port backend lokal:
Menggunakan Emulator Android: http://10.0.2.2:5000/api
Menggunakan iOS Simulator: http://localhost:5000/api

**5. Jalankan Aplikasi di Emulator**
Pastikan emulator (Android/iOS) sudah menyala di perangkat Anda, lalu jalankan:
```Bash
flutter run
