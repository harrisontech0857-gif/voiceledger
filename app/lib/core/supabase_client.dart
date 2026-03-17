import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseAuthProvider = Provider<GotrueClient>((ref) {
  return Supabase.instance.client.auth;
});

final userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser != null;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  return Supabase.instance.client.auth.currentUser;
});

// Watch auth state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
