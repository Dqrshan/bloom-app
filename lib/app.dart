import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/bloom_provider.dart';
import 'theme/bloom_theme.dart';
import 'widgets/bloom_dial.dart';
import 'screens/home/home_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/sync/sync_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/ai/bloom_ai_chat_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/day/day_detail_screen.dart';

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BloomProvider()..loadData(),
      child: MaterialApp(
        title: 'Bloom',
        theme: bloomTheme(),
        darkTheme: bloomDarkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const _AppEntry(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final name = settings.name ?? '/';

  // Concrete day URLs: /day/2025-01-31
  if (name.startsWith('/day/')) {
    final raw = Uri.decodeComponent(name.substring('/day/'.length));
    final date = DateTime.tryParse(raw);
    if (date != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => DayDetailScreen(date: date),
      );
    }
  }

  switch (name) {
    case '/onboarding':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const OnboardingScreen(),
      );
    case '/home':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainShell(),
      );
    case '/calendar':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const CalendarScreen(),
      );
    case '/notes':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const NotesScreen(),
      );
    case '/sync':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SyncScreen(),
      );
    case '/settings':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SettingsScreen(),
      );
    case '/ai':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const BloomAIChatScreen(),
      );
  }
  return null;
}

/// Decides between the first-run tour and the app itself.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late final Future<bool> _hasLaunched = SharedPreferences.getInstance().then(
    (prefs) => prefs.getBool('bloom_has_launched') ?? false,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasLaunched,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _BloomSplash();
        }
        return snapshot.data! ? const MainShell() : const OnboardingScreen();
      },
    );
  }
}

class _BloomSplash extends StatelessWidget {
  const _BloomSplash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BloomMark(size: 92),
            const SizedBox(height: 20),
            Text('Bloom', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app's five top-level destinations.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<WidgetBuilder> _tabs = [
    _buildHome,
    _buildCalendar,
    _buildNotes,
    _buildSync,
    _buildSettings,
  ];

  static Widget _buildHome(BuildContext _) => const HomeScreen();
  static Widget _buildCalendar(BuildContext _) => const CalendarScreen();
  static Widget _buildNotes(BuildContext _) => const NotesScreen();
  static Widget _buildSync(BuildContext _) => const SyncScreen();
  static Widget _buildSettings(BuildContext _) => const SettingsScreen();

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.edit_note_outlined),
      selectedIcon: Icon(Icons.edit_note),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.sync_outlined),
      selectedIcon: Icon(Icons.sync),
      label: 'Sync',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: _TabHost(index: _index, builders: _tabs),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
        ),
      ),
    );
  }
}

/// Keeps every visited tab alive so its state survives a switch, while
/// building a tab only once it is first opened — opening Sync should not
/// reach for the relay before the user asks for it.
class _TabHost extends StatefulWidget {
  final List<WidgetBuilder> builders;
  final int index;

  const _TabHost({required this.builders, required this.index});

  @override
  State<_TabHost> createState() => _TabHostState();
}

class _TabHostState extends State<_TabHost> {
  final List<Widget?> _tabs = [];

  @override
  void initState() {
    super.initState();
    _ensureBuilt(widget.index);
  }

  @override
  void didUpdateWidget(covariant _TabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureBuilt(widget.index);
  }

  void _ensureBuilt(int index) {
    while (_tabs.length <= index) {
      _tabs.add(null);
    }
    if (_tabs[index] == null) {
      _tabs[index] = widget.builders[index](context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < _tabs.length; i++)
          if (_tabs[i] != null)
            Offstage(offstage: i != widget.index, child: _tabs[i]!),
      ],
    );
  }
}
