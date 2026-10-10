import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';
import 'sign_in_screen.dart';

/// Decides what the app shows first: the Sign In screen, or the main tabs
/// if someone is already signed in.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SessionService _session = SessionService();

  /// The signed-in member, or null if nobody is signed in.
  TeamMember? _currentUser;

  /// True while the saved session is being checked at startup.
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  /// Looks for a saved member id and, if that member still exists, signs
  /// them back in without showing the Sign In screen.
  Future<void> _restoreSession() async {
    TeamMember? savedUser;

    try {
      final savedId = await _session.loadCurrentUserId();
      if (savedId != null) {
        final members = await StorageService().loadTeamMembers();
        for (final member in members) {
          if (member.id == savedId) {
            savedUser = member;
          }
        }
      }
    } catch (error) {
      // If the saved session cannot be read, fall back to Sign In.
      savedUser = null;
    }

    if (!mounted) return;
    setState(() {
      _currentUser = savedUser;
      _isChecking = false;
    });
  }

  /// Remembers the chosen member and switches to the main tabs.
  Future<void> _signIn(TeamMember member) async {
    await _session.saveCurrentUserId(member.id);

    if (!mounted) return;
    setState(() {
      _currentUser = member;
    });
  }

  /// Forgets the saved member and switches back to the Sign In screen.
  Future<void> _signOut() async {
    await _session.clear();

    if (!mounted) return;
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = _currentUser;
    if (currentUser == null) {
      return SignInScreen(onSignedIn: _signIn);
    }

    return MainShell(currentUser: currentUser, onSignOut: _signOut);
  }
}
