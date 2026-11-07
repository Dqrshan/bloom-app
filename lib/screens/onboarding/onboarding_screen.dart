import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _pageCtrl = PageController();

  static const _pages = [
    {
      'title': 'Welcome to Bloom',
      'subtitle': 'Your private cycle, mood, and wellness companion.',
      'icon': Icons.local_florist_rounded,
      'color': BloomColors.rose500,
    },
    {
      'title': 'Log your period & symptoms',
      'subtitle': 'Track flow, mood, cramps, and notes day by day.',
      'icon': Icons.water_drop_rounded,
      'color': BloomColors.periodRed,
    },
    {
      'title': 'Understand your cycle',
      'subtitle': 'See your phase, predictions, and patterns over time.',
      'icon': Icons.calendar_today_rounded,
      'color': BloomColors.lavender,
    },
    {
      'title': 'Private by design',
      'subtitle': 'Data stays on your device. Partner sync is end-to-end encrypted.',
      'icon': Icons.shield_rounded,
      'color': BloomColors.sage,
    },
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bloom_has_launched', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BloomColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BloomDesign.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (p['color'] as Color).withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (p['color'] as Color).withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(p['icon'] as IconData, size: 48, color: p['color'] as Color),
                        ),
                        const SizedBox(height: BloomDesign.xxl),
                        Text(
                          p['title'] as String,
                          style: BloomDesign.h2.copyWith(color: BloomColors.ink),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BloomDesign.md),
                        Text(
                          p['subtitle'] as String,
                          style: BloomDesign.body.copyWith(color: BloomColors.inkLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(BloomDesign.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _page == i ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _page == i ? BloomColors.rose500 : BloomColors.divider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: BloomDesign.xxl),
                  if (_page == _pages.length - 1)
                    BloomDesign.primaryButton(
                      label: 'Get started',
                      onPressed: _finish,
                      icon: Icons.arrow_forward_rounded,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: BloomDesign.ghostButton(
                            label: 'Skip',
                            onPressed: _finish,
                          ),
                        ),
                        const SizedBox(width: BloomDesign.md),
                        Expanded(
                          child: BloomDesign.primaryButton(
                            label: _page == _pages.length - 2 ? 'Finish' : 'Next',
                            onPressed: () {
                              if (_page == _pages.length - 2) {
                                _finish();
                              } else {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            icon: Icons.arrow_forward_rounded,
                          ),
                        ),
                      ],
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
