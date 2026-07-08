import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    try {
      debugPrint('[Auth] Attempting login for: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] Login response - user: ${response.user?.id ?? "null"}');
      if (response.user == null) {
        throw Exception('登录失败');
      }
    } on AuthException catch (e) {
      debugPrint('[Auth] AuthException: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Auth] Error: $e');
      rethrow;
    }
  }

  Future<bool> signUp(String email, String password, {String? nickname, String? faithTag, String? username}) async {
    try {
      Map<String, dynamic>? data;
      if (nickname != null || faithTag != null || username != null) {
        data = {};
        if (nickname != null) data['nickname'] = nickname;
        if (faithTag != null) data['faith_tag'] = faithTag;
        if (username != null) data['username'] = username;
      }
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
        emailRedirectTo: 'https://openfaithub.com/#/login',
      );
      return true;
    } on AuthException catch (e) {
      debugPrint('[Auth] signUp error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Auth] signUp error: $e');
      rethrow;
    }
  }

  Future<String> verifyOTP(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      debugPrint('[Auth] verifyOTP - user: ${response.user?.id ?? "null"}');
      if (response.user == null) {
        throw Exception('验证码错误');
      }
      return response.user!.id;
    } on AuthException catch (e) {
      debugPrint('[Auth] verifyOTP error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Auth] verifyOTP error: $e');
      rethrow;
    }
  }

  Future<void> createProfile({
    required String userId,
    required String username,
    required String nickname,
    required String faithTag,
    required String email,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'user_id': userId,
        'username': username,
        'nickname': nickname,
        'faith_tag': faithTag,
        'email': email,
        'hot_points': 5,
      });
      debugPrint('[Auth] Create profile success');
    } catch (e) {
      debugPrint('[Auth] Create profile error: $e');
      rethrow;
    }
  }

  /// 发送密码重置 OTP 验证码
  Future<void> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      debugPrint('[Auth] Password reset OTP sent to: $email');
    } on AuthException catch (e) {
      debugPrint('[Auth] sendPasswordReset error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Auth] sendPasswordReset error: $e');
      rethrow;
    }
  }

  /// 验证重置密码的 OTP
  Future<void> verifyResetOTP(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      if (response.user == null) {
        throw Exception('验证码错误');
      }
      debugPrint('[Auth] Reset OTP verified');
    } on AuthException catch (e) {
      debugPrint('[Auth] verifyResetOTP error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Auth] verifyResetOTP error: $e');
      rethrow;
    }
  }

  /// 更新密码
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('[Auth] Password updated');
    } on AuthException catch (e) {
      debugPrint('[Auth] updatePassword error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Auth] updatePassword error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
