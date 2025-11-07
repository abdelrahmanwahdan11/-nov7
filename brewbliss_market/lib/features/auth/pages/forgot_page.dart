import 'package:flutter/material.dart';

import 'package:brewbliss_market/controllers/auth_controller.dart';
import 'package:brewbliss_market/core/theme/design_tokens.dart';
import 'package:brewbliss_market/core/utils/app_localizations.dart';
import 'package:brewbliss_market/core/utils/validators.dart';
import 'package:brewbliss_market/widgets/primary_button.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.authController.forgotPassword(_emailController.text.trim());
    setState(() => _success = true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('forgot')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('forgot'),
                  style: Theme.of(context).textTheme.titleMedium,
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
                const SizedBox(height: 24),
                PrimaryButton(
                  label: loc.translate('continueLabel'),
                  onPressed: _submit,
                ),
                if (_success) ...[
                  const SizedBox(height: 16),
                  Text(
                    '✔ ${loc.translate('continueLabel')}',
                    style: const TextStyle(color: DesignTokens.success),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
