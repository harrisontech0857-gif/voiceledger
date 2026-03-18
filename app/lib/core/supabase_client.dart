/// Supabase 客戶端設定及提供者
///
/// 此模組負責初始化 Supabase 連線及提供 Riverpod 提供者
/// 支援模擬模式（當外部 API 不可用時）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import 'config.dart';

/// 初始化 Supabase 客戶端
///
/// 應在應用啟動時呼叫此函數
///
/// 範例:
/// ```dart
/// await initSupabase();
/// ```
Future<void> initSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    // 初始化失敗時記錄錯誤
    // 在模擬模式下可安全忽略
    if (!AppConfig.mockMode) {
      rethrow;
    }
  }
}

/// Supabase 客戶端提供者
///
/// 返回全域 Supabase 客戶端實例
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase 認證客戶端提供者
///
/// 返回用於使用者認證操作的 GotrueClient
final supabaseAuthProvider = Provider<GotrueClient>((ref) {
  return Supabase.instance.client.auth;
});

/// 目前使用者 ID 提供者
///
/// 返回已認證使用者的唯一識別碼
/// 未登入時返回 null
final userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

/// 認證狀態提供者
///
/// 檢查使用者是否已登入
/// 返回 true 表示已認證，false 表示未認證
final isAuthenticatedProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser != null;
});

/// 目前使用者非同步提供者
///
/// 取得目前登入的使用者物件
/// 未登入時返回 null
final currentUserProvider = FutureProvider<User?>((ref) async {
  return Supabase.instance.client.auth.currentUser;
});

/// 認證狀態變化監聽提供者
///
/// 監聽認證狀態變化事件
/// 當使用者登入、登出或會話變更時發出事件
///
/// 使用方式:
/// ```dart
/// final authState = ref.watch(authStateChangesProvider);
/// authState.when(
///   data: (state) => print('新狀態: ${state.event}'),
///   loading: () => print('載入中...'),
///   error: (err, _) => print('錯誤: $err'),
/// );
/// ```
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
