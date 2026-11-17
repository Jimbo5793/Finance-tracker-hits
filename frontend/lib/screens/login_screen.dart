import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';
import '../widgets/form_fields.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository repository;
  final AuthSession session;

  const LoginScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _emailError;
  String? _passwordError;

  /// The line above the button: wrong password, or the server can't be reached.
  String? _formError;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final email = _email.text.trim();
    final password = _password.text;
    final emailError = email.isEmpty ? AppStrings.errorEmailRequired : null;
    final passwordError = password.isEmpty
        ? AppStrings.errorPasswordRequired
        : null;

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });
    // Empty fields: show the messages and send nothing.
    if (emailError != null || passwordError != null) return;

    setState(() => _loading = true);
    try {
      final result = await widget.repository.login(
        email: email,
        password: password,
      );
      await widget.session.signIn(result.token, result.expiresAt);
      if (!mounted) return; // the router may already have moved on
      context.go('/wallets');
    } on LoginException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (e.failure == LoginFailure.wrongCredentials) {
          // The email stays, the password is cleared.
          _password.clear();
          _formError = AppStrings.loginWrongCredentials;
        } else {
          // Nothing is wrong with what was typed, so keep it.
          _formError = AppStrings.loginUnavailable;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Logo(),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.loginTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                FormFieldBlock(
                  label: AppStrings.fieldEmail,
                  errorText: _emailError,
                  child: AppTextField(
                    controller: _email,
                    hint: AppStrings.hintEmail,
                    hasError: _emailError != null,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 20),
                FormFieldBlock(
                  label: AppStrings.fieldPassword,
                  errorText: _passwordError,
                  child: AppTextField(
                    controller: _password,
                    hint: AppStrings.hintPassword,
                    hasError: _passwordError != null,
                    enabled: !_loading,
                    obscureText: true,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 20),
                  _ErrorLine(message: _formError!),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.buttonDisabled,
                    disabledForegroundColor: AppColors.buttonDisabledText,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    _loading ? AppStrings.loggingIn : AppStrings.logIn,
                  ),
                ),
                const SizedBox(height: 20),
                const _RegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stand-in for the wallet picture of the design (no image file for it yet).
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.sidebarLogoBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 32,
          color: AppColors.sidebarLogoIcon,
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  final String message;
  const _ErrorLine({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBannerBackground,
        border: Border.all(color: AppColors.errorBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.errorText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }
}

/// The backend has no registration endpoint yet, so the link only says so.
class _RegisterLink extends StatelessWidget {
  const _RegisterLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          AppStrings.noAccount,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.registerComingSoon)),
            ),
            child: const Text(
              AppStrings.register,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
