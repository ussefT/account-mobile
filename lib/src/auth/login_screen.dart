import 'package:flutter/material.dart';

import 'auth_scope.dart';
import '../localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final controller = AuthScope.of(context);
      // If password is disabled, just login without password
      if (!controller.passwordEnabled) {
        final ok = await controller.login(password: '');
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed')),
          );
        }
        return;
      }
      
      final ok = await controller.login(password: _passwordController.text);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong password')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _biometric() async {
    setState(() => _submitting = true);
    try {
      final ok = await AuthScope.of(context).biometricUnlock();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric unlock failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuthScope.of(context);
    final username = controller.username;
    final l10n = AppLocalizations.of(context);
    final passwordRequired = controller.passwordEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (username != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      username,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (passwordRequired)
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) {
                      if ((value ?? '').isEmpty) return l10n.enterPassword;
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _biometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock with biometrics'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
