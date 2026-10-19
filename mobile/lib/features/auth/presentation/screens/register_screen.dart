import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/widgets/language_selector_button.dart';
import '../auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.reject,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final tr = ref.watch(translationsProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.signUp),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguageTogglePill()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr.joinQuitCapping,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.joinSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Display Name
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: tr.displayName,
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return tr.enterNamePrompt;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: tr.email,
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return tr.enterEmailPrompt;
                      if (!val.contains('@')) return tr.validEmailPrompt;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: tr.password,
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return tr.enterPasswordPrompt;
                      if (val.length < 6) return tr.passwordLengthPrompt;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr.createAccount,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr.alreadyHaveAccount,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          tr.logIn,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
