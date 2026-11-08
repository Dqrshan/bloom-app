import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';
import '../../widgets/bloom_dial.dart';

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
      'subtitle':
          'Data stays on your device. Partner sync is end-to-end encrypted.',
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
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const BloomMark(size: 104),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  final color = page['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BloomDesign.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 28,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: p.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BloomDesign.gutter,
                0,
                BloomDesign.gutter,
                BloomDesign.lg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _page == i ? 26 : 8,
                        decoration: BoxDecoration(
                          color: _page == i ? p.period : p.divider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_page == _pages.length - 1)
                    BloomDesign.primaryButton(
                      context,
                      label: 'Get started',
                      onPressed: _finish,
                      icon: Icons.arrow_forward_rounded,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                foregroundColor: p.muted,
                                backgroundColor: p.surfaceAlt,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    BloomDesign.radiusMd,
                                  ),
                                ),
                              ),
                              child: const Text('Skip'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: BloomDesign.primaryButton(
                            context,
                            label: _page == _pages.length - 2
                                ? 'Finish'
                                : 'Next',
                            onPressed: () {
                              if (_page == _pages.length - 2) {
                                _finish();
                              } else {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
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
