import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/bloom_theme.dart';
import 'services/bloom_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/sync/sync_screen.dart';
import 'screens/settings/settings_screen.dart';

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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BloomProvider()..loadData(),
      child: MaterialApp(
        title: 'Bloom',
        theme: bloomTheme(),
        debugShowCheckedModeBanner: false,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    CalendarScreen(),
    NotesScreen(),
    SyncScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: BloomColors.rose100,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined, size: 22), selectedIcon: Icon(Icons.home, size: 22), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined, size: 22), selectedIcon: Icon(Icons.calendar_month, size: 22), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.edit_note_outlined, size: 22), selectedIcon: Icon(Icons.edit_note, size: 22), label: 'Notes'),
            NavigationDestination(icon: Icon(Icons.sync_outlined, size: 22), selectedIcon: Icon(Icons.sync, size: 22), label: 'Sync'),
            NavigationDestination(icon: Icon(Icons.settings_outlined, size: 22), selectedIcon: Icon(Icons.settings, size: 22), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
