import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/student/student_dashboard.dart';
import 'presentation/screens/admin/admin_dashboard.dart';
import 'presentation/screens/common/splash_screen.dart';
import 'presentation/screens/student/submission_screen.dart';
import 'presentation/screens/common/settings_screen.dart';

// New screen imports
import 'presentation/screens/student/task_management_screen.dart';
import 'presentation/screens/student/quiz_list_screen.dart';
import 'presentation/screens/student/quiz_attempt_screen.dart';
import 'presentation/screens/student/study_timer_screen.dart';
import 'presentation/screens/student/analytics_screen.dart';
import 'presentation/screens/admin/create_student_screen.dart';
import 'presentation/screens/admin/schedule_creator.dart';
import 'presentation/screens/admin/resource_management_screen.dart';
import 'presentation/screens/admin/quiz_management_screen.dart';
import 'presentation/screens/admin/submission_review_screen.dart';

// Admin control screens
import 'presentation/screens/admin/admin_tasks_screen.dart';
import 'presentation/screens/admin/admin_timetable_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login',  builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/student', builder: (context, state) => const StudentDashboard()),
    GoRoute(path: '/admin',  builder: (context, state) => const AdminDashboard()),
    GoRoute(path: '/submit', builder: (context, state) => const SubmissionScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    
    // New screens mapping
    GoRoute(path: '/tasks', builder: (context, state) => const TaskManagementScreen()),
    GoRoute(path: '/quiz-list', builder: (context, state) => const QuizListScreen()),
    GoRoute(
      path: '/quiz-attempt/:id',
      builder: (context, state) => QuizAttemptScreen(quizId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/timer', builder: (context, state) => const StudyTimerScreen()),
    GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
    GoRoute(path: '/admin/create-student', builder: (context, state) => const CreateStudentScreen()),
    GoRoute(path: '/admin/schedules', builder: (context, state) => const ScheduleCreator()),
    GoRoute(path: '/admin/resources', builder: (context, state) => const ResourceManagementScreen()),
    GoRoute(path: '/admin/quizzes', builder: (context, state) => const QuizManagementScreen()),
    GoRoute(path: '/admin/submissions', builder: (context, state) => const SubmissionReviewScreen()),
    
    // Admin control screens mapping
    GoRoute(path: '/admin/tasks', builder: (context, state) => const AdminTasksScreen()),
    GoRoute(
      path: '/admin/timetable/:studentId',
      builder: (context, state) => AdminTimetableScreen(studentId: state.pathParameters['studentId']!),
    ),
  ],
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Study Companion',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366),
          primary: const Color(0xFF003366),
          secondary: const Color(0xFFE31E24),
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4D94FF),
          secondary: Color(0xFFFF4D4D),
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
    );
  }
}
