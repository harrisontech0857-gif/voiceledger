import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

/// Supabase 客戶端提供者
///
/// 返回全域 Supabase 客戶端實例
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase 認證客戶端提供者
///
/// 返回用於使用者認證操作的 GoTrueClient
final authProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// 目前使用者 ID 提供者
///
/// 返回已認證使用者的唯一識別碼
/// 未登入時返回 null
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

/// 認證狀態提供者 (AuthState 流)
///
/// 監聽認證狀態變化事件
/// 當使用者登入、登出或會話變更時發出事件
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// 目前登入狀態提供者
///
/// 返回使用者是否已認證
final isAuthenticatedProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser != null;
});
