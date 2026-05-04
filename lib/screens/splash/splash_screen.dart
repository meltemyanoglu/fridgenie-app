import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../routes.dart';
import '../../widgets/animated_blob.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    final done = context.read<UserProvider>().onboardingDone;
    Navigator.of(context).pushReplacementNamed(
      done ? AppRoutes.shell : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned(
            top: -60,
            right: -60,
            child: AnimatedBlob(
              size: 280,
              colors: [AppColors.primaryLight, AppColors.primarySurface],
            ),
          ),
          const Positioned(
            bottom: -80,
            left: -40,
            child: AnimatedBlob(
              size: 240,
              colors: [AppColors.citrus, AppColors.citrusSurface],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _logoCtrl,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.leafGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🧞', style: TextStyle(fontSize: 56)),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _logoCtrl,
                  child: Text('Fridgenie', style: AppTypography.wordmark),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _logoCtrl,
                  child: Text(
                    'Turn ingredients into ideas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
