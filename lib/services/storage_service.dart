import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Menyimpan gambar kartu secara lokal di device.
/// Gambar hanya tersedia di device yang sama — tidak sync ke cloud.
/// Deck publik milik user lain yang punya imageUrl akan tampil placeholder.
class StorageService {
  Future<String> _cardImageDir({
    required String userId,
    required String deckId,
    required String cardId,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(appDir.path, 'card_images', userId, deckId, cardId),
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Simpan gambar ke lokal. Return path absolut file.
  Future<String> uploadCardImage({
    required String userId,
    required String deckId,
    required String cardId,
    required File imageFile,
  }) async {
    final dir = await _cardImageDir(
      userId: userId,
      deckId: deckId,
      cardId: cardId,
    );
    final destPath = p.join(dir, 'question_image.jpg');
    await imageFile.copy(destPath);
    return destPath;
  }

  /// Hapus gambar lokal. Tidak throw error jika tidak ada.
  Future<void> deleteCardImage({
    required String userId,
    required String deckId,
    required String cardId,
  }) async {
    try {
      final dir = await _cardImageDir(
        userId: userId,
        deckId: deckId,
        cardId: cardId,
      );
      final file = File(p.join(dir, 'question_image.jpg'));
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// Cek apakah path adalah file lokal (bukan URL http)
  static bool isLocalPath(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }
}