import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final List<String> _motivationalQuotes = [
    "Believe in yourself and all that you are.",
    "The secret of getting ahead is getting started.",
    "Your education is a dress rehearsal for a life that is yours to lead.",
    "Knowledge is power. Information is liberating.",
    "Focus on being productive instead of busy."
  ];

  late String _currentQuote;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    _currentQuote = _motivationalQuotes[Random().nextInt(_motivationalQuotes.length)];
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _timerDone = true);
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() {
    if (!_timerDone) return;
    final authState = ref.read(authProvider);
    
    if (authState.isLoading) return;
    
    final user = authState.value;
    if (user != null) {
      if (context.mounted) {
        context.go(user.role == 'Admin' ? '/admin' : '/student');
      }
    } else {
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        _checkAuthAndNavigate();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.5, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.school_outlined,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'STUDY COMPANION',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            const SpinKitThreeBounce(
              color: Colors.red,
              size: 30.0,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _currentQuote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
