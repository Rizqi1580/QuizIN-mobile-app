import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'daily_reminder',
          channelName: 'Pengingat Belajar',
          channelDescription: 'Notifikasi pengingat belajar harian',
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
      debug: false,
    );
  }

  static Future<bool> requestPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  static Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    // Cancel dulu sebelum schedule baru
    await cancelReminder();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'daily_reminder',
        title: '📚 Waktunya Belajar!',
        body: 'Jangan lupa review flashcard kamu hari ini.',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelReminder() async {
    await AwesomeNotifications().cancel(1);
  }
}