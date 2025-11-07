import 'package:flutter/material.dart';

import 'package:brewbliss_market/controllers/auth_controller.dart';
import 'package:brewbliss_market/core/theme/design_tokens.dart';
import 'package:brewbliss_market/core/utils/app_localizations.dart';
import 'package:brewbliss_market/core/utils/validators.dart';
import 'package:brewbliss_market/widgets/password_strength_bar.dart';
import 'package:brewbliss_market/widgets/primary_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    widget.authController.updatePasswordStrength(_passwordController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.authController.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('signUp')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.translate('name'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  validator: (value) => Validators.required(value, loc.translate('name')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: loc.translate('emailPhone'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  validator: (value) => Validators.email(value, loc.translate('emailPhone')),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.authController.isPasswordVisible,
                  builder: (context, visible, _) {
                    return TextFormField(
                      controller: _passwordController,
                      obscureText: !visible,
                      decoration: InputDecoration(
                        labelText: loc.translate('password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () =>
                              widget.authController.isPasswordVisible.value = !visible,
                        ),
                      ),
                      validator: (value) => Validators.minLength(value, 8, loc.translate('password')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<double>(
                  valueListenable: widget.authController.passwordStrength,
                  builder: (context, strength, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PasswordStrengthBar(strength: strength),
                        const SizedBox(height: 4),
                        Text(
                          loc.translate('passwordStrength'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.authController.isConfirmVisible,
                  builder: (context, visible, _) {
                    return TextFormField(
                      controller: _confirmController,
                      obscureText: !visible,
                      decoration: InputDecoration(
                        labelText: loc.translate('confirmPassword'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () =>
                              widget.authController.isConfirmVisible.value = !visible,
                        ),
                      ),
                      validator: (value) => Validators.confirmPassword(_passwordController.text.trim(), (value ?? '').trim())
                          ? null
                          : loc.translate('confirmPassword'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: DesignTokens.danger),
                  ),
                PrimaryButton(
                  label: _isLoading ? '${loc.translate('signUp')}...' : loc.translate('signUp'),
                  onPressed: _isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
