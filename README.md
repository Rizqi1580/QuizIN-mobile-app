# QuizIN

Aplikasi belajar interaktif berbasis flashcard dan kuis, dibangun dengan Flutter dan Firebase.

---

## Daftar Isi

- [Fitur Aplikasi](#fitur-aplikasi)
- [Prasyarat](#prasyarat)
- [Clone & Setup](#clone--setup)
- [Konfigurasi Firebase](#konfigurasi-firebase)
- [Build & Jalankan](#build--jalankan)

---

## Fitur Aplikasi

### Autentikasi
- Daftar akun baru dengan email dan password
- Login / logout menggunakan Firebase Authentication
- Otomatis diarahkan ke halaman utama setelah login

### Manajemen Deck
- **Buat deck manual** — isi judul, deskripsi, kategori (Matematika, Sains, Bahasa, Sejarah, Lainnya), dan visibilitas (Publik / Privat)
- **Import deck dari CSV** — unggah file `.csv` untuk membuat deck beserta seluruh kartu secara otomatis; tersedia template dan panduan pengisian di dalam layar import
- Edit dan hapus deck yang sudah ada

### Kartu Flashcard
- Tambah, edit, dan hapus kartu dalam deck
- Setiap kartu memiliki: pertanyaan, jawaban, hingga 4 clue, penjelasan, dan foto opsional (diambil dari kamera atau galeri)

### Mode Flashcard
- Tampilkan kartu satu per satu dengan animasi flip
- Tombol acak urutan kartu (aktif secara default)
- Navigasi maju / mundur antar kartu

### Mode Kuis
- Jawaban pilihan ganda digenerate otomatis dari kartu dalam deck
- Clue bertahap: buka clue 1 → 2 → 3 → 4 sesuai kebutuhan
- Skor akhir, ringkasan jawaban benar/salah, dan ulasan kartu yang salah
- Riwayat sesi kuis tersimpan dan bisa dilihat kembali

### Jelajahi Deck Publik
- Temukan deck yang dibuat pengguna lain (hanya deck Publik)
- Filter berdasarkan kategori dan pencarian teks
- Langsung mulai flashcard dari deck orang lain

### Bookmark
- Simpan deck publik milik pengguna lain sebagai referensi
- Akses cepat dari tab Tersimpan
- Hapus bookmark dengan swipe atau tombol di kartu

### Pengingat Belajar
- Notifikasi harian terjadwal pada jam yang bisa dikustomisasi
- Aktifkan / nonaktifkan dari halaman Pengaturan di profil

### Profil
- Tampilkan nama dan email akun yang sedang login
- Navigasi ke pengaturan pengingat
- Tombol logout

---

## Prasyarat

| Kebutuhan | Versi minimum |
|---|---|
| Flutter SDK | 3.11.5 |
| Dart SDK | 3.11.5 |
| Android SDK | API 21 (Android 5.0) |
| Xcode (untuk iOS) | 15+ |
| Node.js (opsional, untuk Firebase CLI) | 18+ |

---

## Clone & Setup

```bash
# 1. Clone repositori
https://github.com/Rizqi1580/QuizIN-mobile-app.git
cd quiz_flashcard

# 2. Pasang dependensi
flutter pub get
```

---

## Konfigurasi Firebase

Aplikasi ini membutuhkan project Firebase sendiri karena file konfigurasi (`google-services.json`, `GoogleService-Info.plist`, dan `firebase_options.dart`) tidak ikut di-commit ke repositori.

### Langkah-langkah

1. Buka [Firebase Console](https://console.firebase.google.com/) dan buat project baru (atau gunakan project yang sudah ada).

2. Aktifkan layanan berikut di project Firebase:
   - **Authentication** → Sign-in method: Email/Password
   - **Cloud Firestore** → Buat database (mode Production atau Test)

3. Tambahkan aplikasi ke project Firebase:

   **Android:**
   - Tambah Android app dengan package name `com.example.quiz_flashcard`
   - Unduh `google-services.json` dan letakkan di `android/app/`

   **iOS:**
   - Tambah iOS app dengan bundle ID yang sesuai
   - Unduh `GoogleService-Info.plist` dan letakkan di `ios/Runner/`

   **Web / Windows (opsional):**
   - Tambah Web app dan salin konfigurasi yang diberikan

4. Generate ulang `firebase_options.dart` menggunakan FlutterFire CLI:

   ```bash
   # Install FlutterFire CLI jika belum ada
   dart pub global activate flutterfire_cli

   # Login ke Firebase
   firebase login

   # Generate konfigurasi (jalankan dari root project)
   flutterfire configure
   ```

   Pilih project Firebase yang tadi dibuat, centang platform yang diinginkan. File `lib/firebase_options.dart` akan dibuat otomatis.

5. Atur Firestore Security Rules (contoh untuk development):

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

---

## Build & Jalankan

### Android (debug)

```bash
# Pastikan emulator atau perangkat fisik sudah terdeteksi
flutter devices

# Jalankan di perangkat Android
flutter run
```

### Android (release APK)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (debug, hanya macOS)

```bash
flutter run -d <device-id>
```

### Web

```bash
flutter run -d chrome
# Atau build statis:
flutter build web
```

### Windows

```bash
flutter run -d windows
# Atau build exe:
flutter build windows
```

---

### Catatan: Izin Notifikasi (Android 13+)

Pada Android 13 ke atas, izin `POST_NOTIFICATIONS` akan diminta saat pengguna pertama kali mengaktifkan pengingat di halaman Pengaturan. Pastikan izin diberikan agar notifikasi harian berfungsi.
