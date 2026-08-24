import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/design_tokens.dart';
import '../../shared/widgets/animated_button.dart';

/// Onboarding carousel — 3 screens with swipeable pages and progress dots.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      imagePath: 'assets/images/logo.jpg',
      title: 'Welcome to Budget Buddy',
      subtitle:
          'Your personal AI-powered finance coach.\nTrack spending, set budgets, and build smarter money habits.',
      gradient: [Color(0xFF006C49), Color(0xFF10B981)],
    ),
    _OnboardingPageData(
      icon: Icons.touch_app_rounded,
      title: 'Simple Manual Tracking',
      subtitle:
          'No SMS permissions, no bank access needed.\nLog expenses in under 5 seconds — just tap, type, done.',
      gradient: [Color(0xFF2B6954), Color(0xFF14B8A6)],
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Insights',
      subtitle:
          'Get personalized budget advice grounded in your real spending.\n"Can I afford a new phone this month?" — just ask!',
      gradient: [Color(0xFF10B981), Color(0xFF6FFBBE)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppAnimation.normal,
        curve: AppAnimation.defaultCurve,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text(
                  'Skip',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPage(data: page);
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: AppAnimation.normal,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withAlpha(77),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Action button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Page Data ──

class _OnboardingPageData {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPageData({
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

// ── Single Onboarding Page ──

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle with gradient
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: data.gradient.first.withAlpha(64),
                  blurRadius: 48,
                  spreadRadius: 0,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: data.imagePath != null
                ? ClipOval(
                    child: Image.asset(
                      data.imagePath!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    data.icon,
                    size: 72,
                    color: Colors.white,
                  ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: AppSpacing.xxxl),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.lg),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
