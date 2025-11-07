import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.appController});

  final AppController appController;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _percentController;
  late final Animation<double> _percentAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _percentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _percentAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _percentController, curve: Curves.easeOut),
    );
    _percentController.forward();
    _timer = Timer(const Duration(milliseconds: 1200), _handleNext);
  }

  Future<void> _handleNext() async {
    if (!mounted) return;
    final shouldShowOnboarding = widget.appController.isFirstLaunch;
    final route = shouldShowOnboarding ? '/onboarding' : '/home';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: DesignTokens.onPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignTokens.onPrimary,
                  width: DesignTokens.strokeBold,
                ),
              ),
              child: Center(
                child: Text(
                  locale.translate('appName'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: DesignTokens.onPrimary,
                      ),
                ),
              ),
            ).animate().scale(duration: 600.ms, begin: 0.9, end: 1.0),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _percentAnimation,
              builder: (context, _) {
                return Text(
                  '${_percentAnimation.value.toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: DesignTokens.onPrimary,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
