import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../core/network/api_client.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  final _api = ApiClient();

  @override
  Future<UserModel?> build() async {
    // Called once on creation — loads user from stored token
    return _loadUser();
  }

  Future<UserModel?> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        final response = await _api.dio.get('/auth/me');
        return UserModel.fromJson(response.data);
      }
    } catch (_) {
      // Token invalid or expired — clear it
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
    }
    return null;
  }

  Future<void> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      final user = UserModel.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', user.token!);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    state = const AsyncValue.data(null);
  }
}
