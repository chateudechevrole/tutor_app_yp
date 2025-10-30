import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Student Profile')),
    body: const Center(
      child: Text('Account settings + booking history (TODO)'),
    ),
  );
}
