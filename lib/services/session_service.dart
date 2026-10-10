import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which team member is signed in on this device.
///
/// Only the member's id is saved. There is no password and no real
/// authentication; this is a local "who is using the app" choice.
class SessionService {
  static const String _currentUserKey = 'current_user_id';

  /// Returns the saved member id, or null if nobody is signed in.
  Future<String?> loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  /// Saves the member id so the app opens straight to the tabs next time.
  Future<void> saveCurrentUserId(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, memberId);
  }

  /// Forgets the signed-in member. Used when signing out.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
