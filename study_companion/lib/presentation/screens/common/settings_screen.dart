import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authProvider).value;
    final isDark    = ref.watch(themeProvider.notifier).isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Profile Information'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.fullName ?? ''),
            subtitle: const Text('Full Name'),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(user?.email ?? 'Not set'),
            subtitle: const Text('Email'),
          ),
          if (user?.phone != null)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(user?.phone ?? ''),
              subtitle: const Text('Phone Number'),
            ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(user?.role ?? ''),
            subtitle: const Text('Role'),
          ),
          const Divider(),

          // ── Preferences ──────────────────────────────────────────
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode_outlined),
            value: isDark,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),
          const Divider(),

          // ── App Info ─────────────────────────────────────────────
          _buildSectionHeader('App Info'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.1'),
          ),
          const Divider(),

          // ── Logout ───────────────────────────────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('LOGOUT'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }
}
