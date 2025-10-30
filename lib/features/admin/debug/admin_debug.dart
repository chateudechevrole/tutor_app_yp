import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> debugPromoteToAdmin(BuildContext context) async {
  if (!kDebugMode) return;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sign in first.')));
    return;
  }
  await FirebaseFirestore.instance.doc('users/${user.uid}').set({
    'role': 'admin',
    'email': user.email,
    'displayName': user.displayName ?? 'Admin',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Promoted to admin (debug).')));
}
