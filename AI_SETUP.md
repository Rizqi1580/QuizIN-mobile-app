# Setup Google Gemini AI Service

## Langkah 1: Dapatkan API Key dari Google

1. Buka https://aistudio.google.com/app/apikey
2. Klik **"Create API key in new project"**
3. Copy API key yang sudah di-generate

## Langkah 2: Update API Key di AIService

Edit file `lib/services/ai_service.dart` dan ganti:

```dart
static const String _apiKey = 'AIzaSyBMeQKqkq8q8Q8q8Q8q8Q8q8Q8q8Q8q'; 
```

Dengan API key kamu:

```dart
static const String _apiKey = 'AIzaSyD_XXXXX_YOUR_API_KEY_XXXXX';
```

## Langkah 3: Test

Buat card baru tanpa penjelasan. Sistem akan otomatis:
1. Validate form
2. Show loading indicator
3. Call Gemini API untuk generate penjelasan
4. Save ke Firestore

## Features

✅ Auto-generate penjelasan saat user membuat card
✅ Jika penjelasan kosong → AI generate secara otomatis
✅ User bisa edit/override penjelasan AI
✅ Fallback penjelasan jika AI API error
✅ Loading state di UI saat generate

## Troubleshooting

- **Error: API key invalid** → Cek format API key
- **Error: Timeout** → Gemini API sedang lambat, tunggu
- **Error: Quota exceeded** → Tunggu sampai quota reset (free tier: 60 requests/menit)

