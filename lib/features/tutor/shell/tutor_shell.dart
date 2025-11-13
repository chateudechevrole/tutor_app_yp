import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../tutor_dashboard_screen.dart';
import '../tutor_messages_screen.dart';
import '../tutor_profile_edit_screen.dart';
import '../../../theme/tutor_theme.dart';
import '../../../data/repositories/tutor_repository.dart';

class TutorShell extends StatefulWidget {
  const TutorShell({super.key});

  @override
  State<TutorShell> createState() => _TutorShellState();
}

class _TutorShellState extends State<TutorShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _tutorRepo = TutorRepo();
  bool _markedOfflineFromLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markOffline(force: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markedOfflineFromLifecycle = false;
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _markOffline();
    }
  }

  void _markOffline({bool force = false}) {
    if (!force && _markedOfflineFromLifecycle) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _tutorRepo.setOnline(uid, false).catchError((_) {});
    _markedOfflineFromLifecycle = true;
  }

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
