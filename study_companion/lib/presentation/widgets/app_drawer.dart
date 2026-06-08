import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authProvider).value;
    final isDark = ref.watch(themeProvider.notifier).isDark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            accountName: Text(
              user?.fullName ?? 'Guest User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? user?.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 30),
            ),
          ),

          // Dashboard (Home)
          _buildDrawerItem(context, Icons.dashboard_outlined, 'Home Dashboard', () {
            Navigator.pop(context);
            context.go(user?.role == 'Admin' ? '/admin' : '/student');
          }),

          // Student modules (Expandable)
          if (user?.role == 'Student')
            ExpansionTile(
              initiallyExpanded: true,
              leading: Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Student Hub', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                _buildDrawerItem(context, Icons.calendar_today_outlined, 'My Schedule', () {
                  Navigator.pop(context);
                  context.go('/student');
                }),
                _buildDrawerItem(context, Icons.assignment_outlined, 'My Tasks', () {
                  Navigator.pop(context);
                  context.push('/tasks');
                }),
                _buildDrawerItem(context, Icons.quiz_outlined, 'Quizzes', () {
                  Navigator.pop(context);
                  context.push('/quiz-list');
                }),
                _buildDrawerItem(context, Icons.timer_outlined, 'Study Focus Timer', () {
                  Navigator.pop(context);
                  context.push('/timer');
                }),
                _buildDrawerItem(context, Icons.camera_alt_outlined, 'Submissions', () {
                  Navigator.pop(context);
                  context.push('/submit');
                }),
                _buildDrawerItem(context, Icons.bar_chart_outlined, 'Analytics & Progress', () {
                  Navigator.pop(context);
                  context.push('/analytics');
                }),
              ],
            ),

          // Admin modules (Expandable)
          if (user?.role == 'Admin')
            ExpansionTile(
              initiallyExpanded: true,
              leading: Icon(Icons.admin_panel_settings_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                _buildDrawerItem(context, Icons.people_outline, 'Student Accounts', () {
                  Navigator.pop(context);
                  context.go('/admin');
                }),
                _buildDrawerItem(context, Icons.person_add_outlined, 'Create Student', () {
                  Navigator.pop(context);
                  context.push('/admin/create-student');
                }),
                _buildDrawerItem(context, Icons.calendar_today_outlined, 'Plan Schedules', () {
                  Navigator.pop(context);
                  context.push('/admin/schedules');
                }),
                _buildDrawerItem(context, Icons.menu_book_outlined, 'Link Resources', () {
                  Navigator.pop(context);
                  context.push('/admin/resources');
                }),
                _buildDrawerItem(context, Icons.check_box_outlined, 'Manage Quizzes', () {
                  Navigator.pop(context);
                  context.push('/admin/quizzes');
                }),
                _buildDrawerItem(context, Icons.rate_review_outlined, 'Review Submissions', () {
                  Navigator.pop(context);
                  context.push('/admin/submissions');
                }),
              ],
            ),

          const Divider(),

          // Dark mode toggle
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Dark Mode'),
            value: isDark,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),

          // Settings
          _buildDrawerItem(context, Icons.settings_outlined, 'Settings', () {
            Navigator.pop(context);
            context.push('/settings');
          }),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
