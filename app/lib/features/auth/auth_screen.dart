import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _isLogin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    // 監聽 OAuth 回調 — 登入成功後自動導航
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn && mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = '請輸入郵箱和密碼');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = '密碼至少需要 6 個字元');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;

      if (_isLogin) {
        await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final res = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // 如果需要驗證郵件
        if (res.user != null && res.session == null) {
          if (mounted) {
            setState(() {
              _errorMessage = null;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('註冊成功！請查看郵箱完成驗證'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _translateAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = '連線錯誤，請檢查網路: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;

      if (kIsWeb) {
        // Web 端：使用 PKCE flow，redirectTo 用目前頁面的 origin
        // 確保 OAuth callback 回到同一個 origin，避免 state mismatch
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      } else {
        // Mobile 端：使用 deep link callback
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.voiceledger://login-callback/',
        );
      }
      // OAuth 會導向瀏覽器，成功後 onAuthStateChange 會觸發導航
    } on AuthException catch (e) {
      if (e.message.contains('oauth_state') || e.message.contains('state')) {
        setState(() => _errorMessage = 'OAuth 狀態過期，請重新點擊登入');
      } else {
        setState(() => _errorMessage = _translateAuthError(e.message));
      }
    } catch (e) {
      setState(() => _errorMessage = 'Google 登入失敗: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = '請先輸入郵箱，再點擊忘記密碼');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密碼重設信已寄出，請查看收件匣'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _translateAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = '發送重設信失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return '郵箱或密碼錯誤';
    }
    if (message.contains('Email not confirmed')) {
      return '郵箱尚未驗證，請查看收件匣';
    }
    if (message.contains('User already registered')) {
      return '此郵箱已註冊，請直接登入';
    }
    if (message.contains('Password should be at least')) {
      return '密碼至少需要 6 個字元';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // 標題
                Text(
                  '語記',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'AI 財務秘書',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 標籤切換器
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: '登入',
                          isActive: _isLogin,
                          onTap: () => setState(() => _isLogin = true),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: '註冊',
                          isActive: !_isLogin,
                          onTap: () => setState(() => _isLogin = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 錯誤訊息
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 郵箱輸入
                Semantics(
                  label: '郵箱地址輸入欄',
                  textField: true,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: '郵箱',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 密碼輸入
                Semantics(
                  label: '密碼輸入欄',
                  textField: true,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: '密碼',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                  ),
                ),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: const Text('忘記密碼？'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // 提交按鈕
                Semantics(
                  button: true,
                  enabled: !_isLoading,
                  label: _isLogin ? '登入帳戶' : '建立新帳戶',
                  onTap: _isLoading ? null : _authenticate,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? '登入' : '建立帳戶'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 分隔線
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        '或',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Google 登入按鈕
                Semantics(
                  button: true,
                  enabled: !_isLoading,
                  label: '用 Google 帳戶登入',
                  onTap: _isLoading ? null : _signInWithGoogle,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('用 Google 帳戶登入'),
                      onPressed: _isLoading ? null : _signInWithGoogle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 標籤按鈕小部件
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: true,
      selected: isActive,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive ? Theme.of(context).colorScheme.onPrimary : null,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
