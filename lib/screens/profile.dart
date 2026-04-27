import 'package:quiz_flashcard/screens/login.dart';
import 'package:quiz_flashcard/screens/settings/reminder_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    navigator.pushReplacementNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account Information'),
              centerTitle: true,
            ),
            body: Column(
              children: [
                const SizedBox(height: 24),
                // Info akun
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          (user.email ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.email ?? '-',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),

                // Menu pengaturan
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Pengingat Belajar'),
                  subtitle: const Text('Atur jadwal reminder harian'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReminderSettingsScreen(),
                    ),
                  ),
                ),

                const Divider(),
                const Spacer(),

                // Tombol logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}