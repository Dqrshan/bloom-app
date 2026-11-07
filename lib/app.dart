import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/bloom_provider.dart';
import 'theme/bloom_theme.dart';
import 'theme/design_system.dart';
import 'screens/home/home_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/ai/bloom_ai_chat_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/day/day_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const BloomApp());
}

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => BloomProvider()..loadData(),
    child: MaterialApp(
      title: 'Bloom',
      theme: bloomTheme(),
      debugShowCheckedModeBanner: false,
      home: const _AppEntry(),
      onGenerateRoute: (settings) {
        // Handle named routes
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/calendar':
            return MaterialPageRoute(builder: (_) => const CalendarScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/ai':
            return MaterialPageRoute(builder: (_) => const BloomAIChatScreen());
          case '/day/:date':
            // Extract date from path
            final uri = Uri.parse(settings.name!);
            final pathSegments = uri.pathSegments;
            if (pathSegments.length > 1 && pathSegments.first == 'day') {
              final date = DateTime.parse(pathSegments.join('/'));
              return MaterialPageRoute(builder: (_) => DayDetailScreen(date: date));
            }
            return null;
          default:
            return null;
        }
      },
    ),
  );
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance()
          .then((p) => p.getBool('bloom_has_launched') ?? false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: BloomColors.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: BloomColors.rose500.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_florist_rounded, size: 44, color: BloomColors.rose500),
                  ),
                  SizedBox(height: BloomDesign.lg),
                  Text('Bloom', style: BloomDesign.h2.copyWith(color: BloomColors.ink)),
                  SizedBox(height: BloomDesign.sm),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(BloomColors.rose500),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final launched = snapshot.data!;
        if (launched) {
          return const HomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}
