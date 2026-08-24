import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/design_tokens.dart';
import '../../shared/animations/reduce_motion.dart';

/// Splash screen with animated logo, floating Y-axis animation,
/// and "Initializing AI..." loading indicator.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Navigate after splash duration
    Future.delayed(AppAnimation.splash, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final noMotion = context.reduceMotion;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.surfaceDark,
                    const Color(0xFF0A2818),
                    AppColors.surfaceDark,
                  ]
                : [
                    AppColors.surfaceLight,
                    const Color(0xFFD1FAE5),
                    AppColors.surfaceLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // ── Floating Logo ──
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final offset = noMotion
                      ? 0.0
                      : 8.0 *
                          Curves.easeInOut
                              .transform(_floatController.value);
                  return Transform.translate(
                    offset: Offset(0, -offset),
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.heroAll,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withAlpha(77),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.heroAll,
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // ── App Name ──
              Text(
                'Budget Buddy',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),

              const SizedBox(height: AppSpacing.sm),

              // ── Tagline ──
              Text(
                'Your AI-Powered Finance Coach',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms),

              const Spacer(flex: 2),

              // ── Loading Indicator ──
              Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: LinearProgressIndicator(
                        backgroundColor:
                            theme.colorScheme.outline.withAlpha(51),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Initializing AI...',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 500.ms),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
