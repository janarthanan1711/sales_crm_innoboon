import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/di/injector.dart';
import '../../domain/usecases/password_reset_usecases.dart';

/// Landing page for the link emailed by `POST /auth/forgot-password`
/// (`/reset-password?token=...`). [token] is read from that query param by
/// the router; a missing token means the link was malformed or truncated,
/// not a token the backend could ever validate, so it's treated the same as
/// an invalid one without a network round-trip.
class ResetPasswordPage extends StatefulWidget {
  final String? token;
  const ResetPasswordPage({super.key, this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _done = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<ResetPasswordUseCase>()(
      ResetPasswordParams(token: widget.token!, newPassword: _newController.text),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => messenger.showSnackBar(
        // Backend's only failure mode here is "Invalid or expired reset
        // token" (400) — safe to show directly, nothing internal to leak.
        SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
      ),
      (_) => setState(() => _done = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: widget.token == null || widget.token!.isEmpty
                ? _buildInvalidLinkView()
                : (_done ? _buildSuccessView() : _buildFormView()),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set a new password', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose a new password for your account.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text('New Password', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _newController,
            obscureText: _obscure,
            validator: Validators.password,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Confirm New Password', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure,
            validator: Validators.password,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline, size: 20)),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            height: AppSpacing.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Reset Password'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
        const SizedBox(height: AppSpacing.xxl),
        Text('Password reset', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your password has been updated. Sign in with your new password.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          height: AppSpacing.buttonHeightLarge,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(RoutePaths.login),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidLinkView() {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 72, color: AppColors.error),
        const SizedBox(height: AppSpacing.xxl),
        Text('Invalid reset link', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'This password reset link is missing its token. Request a new one.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          height: AppSpacing.buttonHeightLarge,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(RoutePaths.forgotPassword),
            child: const Text('Request New Link'),
          ),
        ),
      ],
    );
  }
}
