import 'package:flutter/material.dart';
import '../tutor_dashboard_screen.dart';
import '../tutor_messages_screen.dart';
import '../tutor_profile_edit_screen.dart';
import '../../../theme/tutor_theme.dart';

class TutorShell extends StatefulWidget {
  const TutorShell({super.key});

  @override
  State<TutorShell> createState() => _TutorShellState();
}

class _TutorShellState extends State<TutorShell> {
  int _selectedIndex = 0;

  static const _titles = ['Home', 'Messages', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: kBg,
      ),
      backgroundColor: kBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TutorDashboardScreen(),
          TutorMessagesScreen(),
          TutorProfileEditScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
