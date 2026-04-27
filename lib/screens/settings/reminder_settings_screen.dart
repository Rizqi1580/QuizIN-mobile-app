import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/services/notification_service.dart';
import 'package:quiz_flashcard/services/notification_settings_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await _settingsService.getSettings(user.uid);

    if (mounted) {
      setState(() {
        if (data != null) {
          _isEnabled = data['isReminderEnabled'] as bool? ?? false;
          _selectedTime = TimeOfDay(
            hour: data['reminderHour'] as int? ?? 8,
            minute: data['reminderMinute'] as int? ?? 0,
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onToggleReminder(bool value) async {
    if (value) {
      // Minta izin notifikasi dulu saat mengaktifkan
      final granted = await NotificationService.requestPermission();
      if (!mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin notifikasi diperlukan'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Tetap nonaktif
      }
    }

    setState(() => _isEnabled = value);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Pilih Jam Pengingat',
    );

    if (result != null && mounted) {
      setState(() => _selectedTime = result);
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      if (_isEnabled) {
        await NotificationService.scheduleDailyReminder(
          _selectedTime.hour,
          _selectedTime.minute,
        );
      } else {
        await NotificationService.cancelReminder();
      }

      await _settingsService.saveSettings(
        user.uid,
        _isEnabled,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pengaturan disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Belajar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Switch aktifkan reminder
                  Card(
                    child: SwitchListTile(
                      title: const Text('Aktifkan Pengingat'),
                      subtitle: const Text(
                          'Notifikasi harian untuk belajar flashcard'),
                      value: _isEnabled,
                      onChanged: _onToggleReminder,
                      secondary: Icon(
                        _isEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        color: _isEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),

                  // Pilih jam — hanya tampil kalau reminder aktif
                  if (_isEnabled) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Jam Pengingat'),
                        subtitle: Text(
                          _formatTime(_selectedTime),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickTime,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Kamu akan mendapat notifikasi setiap hari pukul ${_formatTime(_selectedTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan Pengaturan'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}