import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsRef(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications');

  /// Simpan pengaturan reminder ke Firestore
  Future<void> saveSettings(
    String userId,
    bool isEnabled,
    int hour,
    int minute,
  ) async {
    await _settingsRef(userId).set({
      'isReminderEnabled': isEnabled,
      'reminderHour': hour,
      'reminderMinute': minute,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Ambil pengaturan reminder dari Firestore
  /// Return null jika belum pernah disimpan
  Future<Map<String, dynamic>?> getSettings(String userId) async {
    final doc = await _settingsRef(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data();
  }
}