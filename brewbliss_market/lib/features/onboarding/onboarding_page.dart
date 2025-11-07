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

  final List<(String, String)> _slideKeys = const [
    ('onboardTitle1', 'onboardDesc1'),
    ('onboardTitle2', 'onboardDesc2'),
    ('onboardTitle3', 'onboardDesc3'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(milliseconds: 3000), (_) => _nextPage());
  }

  void _nextPage() {
    if (!mounted) return;
    if (_index < _slideKeys.length - 1) {
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
    final slides = _slideKeys
        .map((keys) => (loc.translate(keys.$1), loc.translate(keys.$2)))
        .toList();
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
                itemCount: _slideKeys.length,
                itemBuilder: (context, index) {
                  final data = slides[index];
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
                      _slideKeys.length,
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
                    child: Text(_index == _slideKeys.length - 1
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
