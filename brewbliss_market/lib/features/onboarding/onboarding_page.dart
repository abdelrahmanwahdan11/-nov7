import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.appController});

  final AppController appController;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  late Timer _timer;
  int _index = 0;

  final _slides = const [
    (
      'Brew & Collect',
      'Discover coffee-inspired collectibles crafted with love.',
    ),
    (
      'Rotate in 3D',
      'Inspect every angle before you bring it home.',
    ),
    (
      'Share the Joy',
      'Sell or keep items while welcoming fresh offers.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(milliseconds: 3000), (_) => _nextPage());
  }

  void _nextPage() {
    if (!mounted) return;
    if (_index < _slides.length - 1) {
      _index++;
      _pageController.animateToPage(
        _index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {});
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer.cancel();
    widget.appController.completeOnboarding();
    Navigator.of(context).pushReplacementNamed('/auth/signin');
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() => _index = value);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final data = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.$1,
                          style: GoogleFonts.caveat(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.ink,
                          ),
                        ).animate().fadeIn(duration: 800.ms).moveY(begin: 16, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          data.$2,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ).animate().fadeIn(duration: 800.ms).moveY(begin: 16, end: 0),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text(loc.translate('skip')),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _index == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _index == index
                              ? DesignTokens.primary
                              : DesignTokens.muted,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_index == _slides.length - 1
                        ? loc.translate('getStarted')
                        : loc.translate('next')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
