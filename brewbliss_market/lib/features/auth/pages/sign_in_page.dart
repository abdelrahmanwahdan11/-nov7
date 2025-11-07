import 'package:flutter/material.dart';

import 'package:brewbliss_market/controllers/auth_controller.dart';
import 'package:brewbliss_market/core/theme/design_tokens.dart';
import 'package:brewbliss_market/core/utils/app_localizations.dart';
import 'package:brewbliss_market/core/utils/validators.dart';
import 'package:brewbliss_market/widgets/primary_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.authController
          .signIn(_identifierController.text.trim(), _passwordController.text.trim());
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
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 24),
                Text(
                  loc.translate('signIn'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    labelText: loc.translate('emailPhone'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  validator: (value) => Validators.required(value, loc.translate('emailPhone')),
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
                          onPressed: () => widget.authController.isPasswordVisible.value = !visible,
                        ),
                      ),
                      validator: (value) => Validators.minLength(value, 8, loc.translate('password')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: DesignTokens.danger),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/auth/forgot'),
                    child: Text(loc.translate('forgot')),
                  ),
                ),
                PrimaryButton(
                  label: _isLoading
                      ? '${loc.translate('signIn')}...'
                      : loc.translate('signIn'),
                  onPressed: _isLoading ? null : _submit,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    widget.authController.continueAsGuest();
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  child: Text(loc.translate('guest')),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/auth/signup'),
                  child: Text(loc.translate('signUp')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
