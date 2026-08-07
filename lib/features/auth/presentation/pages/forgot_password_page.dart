import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/di/injector.dart';
import '../../domain/usecases/password_reset_usecases.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<ForgotPasswordUseCase>()(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: const Text('Could not send the reset link. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => setState(() => _submitted = true),
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
            child: _submitted ? _buildSuccessView() : _buildFormView(),
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
          IconButton(
            alignment: Alignment.centerLeft,
            onPressed: () => context.go(RoutePaths.login),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Forgot password?', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter your email and we\'ll send you a reset link.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text('Email', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            decoration: const InputDecoration(
              hintText: 'you@company.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            height: AppSpacing.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Check your email', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          height: AppSpacing.buttonHeightLarge,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(RoutePaths.login),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}
