import 'package:flutter/material.dart';
import '../student_home_screen.dart';
import '../messages/student_messages_screen.dart';
import '../profile/student_profile_screen.dart';
import '../../../theme/student_theme.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kStudentBg,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentHomeScreen(),
          StudentMessagesScreen(),
          StudentProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
