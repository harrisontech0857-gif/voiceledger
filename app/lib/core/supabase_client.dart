import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show kMockMode;

/// Supabase 客戶端提供者
///
/// Mock 模式下返回 null，需要在使用端判斷
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (kMockMode) return null;
  return Supabase.instance.client;
});

/// Supabase 認證客戶端提供者
final authProvider = Provider<GoTrueClient?>((ref) {
  if (kMockMode) return null;
  return ref.watch(supabaseClientProvider)?.auth;
});

/// 目前使用者 ID 提供者
///
/// Mock 模式返回假 ID
final currentUserIdProvider = Provider<String?>((ref) {
  if (kMockMode) return 'mock-user-001';
  return Supabase.instance.client.auth.currentUser?.id;
});

/// 認證狀態提供者 (AuthState 流)
///
/// Mock 模式返回空流
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (kMockMode) {
    return const Stream<AuthState>.empty();
  }
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// 目前登入狀態提供者
///
/// Mock 模式永遠返回 true
final isAuthenticatedProvider = Provider<bool>((ref) {
  if (kMockMode) return true;
  return Supabase.instance.client.auth.currentUser != null;
});
