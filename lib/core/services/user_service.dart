import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  static const String _userKey = 'app_user_data';
  static const String _authTokenKey = 'app_auth_token';

  /// Save user data to local storage
  static Future<bool> saveUser(UserModel user, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user data
      await prefs.setString(_userKey, user.toJsonString());
      
      // Save auth token if provided
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_authTokenKey, token);
      }
      
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Get saved user data from local storage
  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson == null) return null;
      
      return UserModel.fromJsonString(userJson);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Get saved auth token
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }

  /// Clear user data (logout)
  static Future<bool> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authTokenKey);
      return true;
    } catch (e) {
      print('Error clearing user: $e');
      return false;
    }
  }

  static Future<bool> updateUser(UserModel updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, updatedUser.toJsonString());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  static Future<void> saveFcmToken(String token) async {
  try {
    await ApiClient.post('/users/fcm-token', {'token': token});
  } catch (e) {
    print('Error saving FCM token: $e');
  }
}
}