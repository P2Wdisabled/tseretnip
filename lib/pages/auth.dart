import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true; // true = Login, false = Register
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _repository = SupabaseRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Connexion
        await _repository.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Inscription - utilise le repository qui va aussi insérer dans accounts
        await _repository.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin
                  ? FlutterI18n.translate(context, 'auth.login_success')
                  : FlutterI18n.translate(context, 'auth.register_success'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${FlutterI18n.translate(context, 'auth.error_prefix')}$error',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo ou titre
                  Icon(
                    Icons.photo_camera,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    FlutterI18n.translate(context, 'app_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Titre du formulaire
                  Text(
                    _isLogin
                        ? FlutterI18n.translate(context, 'auth.login_title')
                        : FlutterI18n.translate(context, 'auth.register_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Champ Username (uniquement pour l'inscription)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: FlutterI18n.translate(
                          context,
                          'auth.username_label',
                        ),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return FlutterI18n.translate(
                            context,
                            'auth.username_required',
                          );
                        }
                        if (value.length < 3) {
                          return FlutterI18n.translate(
                            context,
                            'auth.username_length',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: FlutterI18n.translate(
                        context,
                        'auth.email_label',
                      ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return FlutterI18n.translate(
                          context,
                          'auth.email_required',
                        );
                      }
                      if (!value.contains('@')) {
                        return FlutterI18n.translate(
                          context,
                          'auth.email_invalid',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: FlutterI18n.translate(
                        context,
                        'auth.password_label',
                      ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return FlutterI18n.translate(
                          context,
                          'auth.password_required',
                        );
                      }
                      if (value.length < 6) {
                        return FlutterI18n.translate(
                          context,
                          'auth.password_length',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bouton de soumission
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isLogin
                                ? FlutterI18n.translate(
                                    context,
                                    'auth.login_button',
                                  )
                                : FlutterI18n.translate(
                                    context,
                                    'auth.register_button',
                                  ),
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Lien pour basculer entre login et register
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? FlutterI18n.translate(context, 'auth.no_account')
                          : FlutterI18n.translate(context, 'auth.have_account'),
                    ),
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
