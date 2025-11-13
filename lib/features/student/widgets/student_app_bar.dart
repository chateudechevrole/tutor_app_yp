import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/student_theme.dart';
import '../shell/student_shell.dart';

class StudentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int activeIndex;

  const StudentAppBar({
    super.key,
    required this.title,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: kStudentDeep,
      elevation: 1,
      shadowColor: Colors.black12,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        title,
        style: const TextStyle(
          color: kStudentDeep,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        _NavIcon(
          icon: activeIndex == 0 ? Icons.home : Icons.home_outlined,
          label: 'Home',
          isActive: activeIndex == 0,
          onTap: () => StudentShell.of(context)?.navigateToTab(0),
        ),
        _NavIcon(
          icon: activeIndex == 1 ? Icons.message : Icons.message_outlined,
          label: 'Messages',
          isActive: activeIndex == 1,
          onTap: () => StudentShell.of(context)?.navigateToTab(1),
        ),
        _NavIcon(
          icon: activeIndex == 2 ? Icons.person : Icons.person_outline,
          label: 'Profile',
          isActive: activeIndex == 2,
          onTap: () => StudentShell.of(context)?.navigateToTab(2),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: kStudentDeep),
      ),
    );
  }
}
