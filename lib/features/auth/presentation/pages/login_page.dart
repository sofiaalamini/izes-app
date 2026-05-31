import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _clientIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _authService.register(
          nome: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          clienteId: _clientIdController.text,
        );
      } else {
        await _authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() {
        _errorMessage = _isRegisterMode
            ? 'Nao foi possivel concluir o cadastro.'
            : 'Nao foi possivel entrar agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          children: [
            const SizedBox(height: 18),
            Text(
              'IZES',
              style: theme.headlineLarge?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRegisterMode
                  ? 'Crie seu acesso para acompanhar a operacao.'
                  : 'Entre para acompanhar sua propriedade.',
              style: theme.bodyLarge?.copyWith(color: IzesColors.muted),
            ),
            const SizedBox(height: 18),
            Container(
              height: 6,
              width: 72,
              decoration: BoxDecoration(
                color: IzesColors.green,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 24),
            AppSurfaceCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRegisterMode ? 'Cadastro' : 'Login',
                      style: theme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    if (_isRegisterMode) ...[
                      _FieldLabel('Nome'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Como voce quer aparecer no app',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) {
                            return 'Informe seu nome completo.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    const _FieldLabel('E-mail'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'voce@empresa.com',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return 'Informe seu e-mail.';
                        }
                        if (!text.contains('@') || !text.contains('.')) {
                          return 'Digite um e-mail valido.';
                        }
                        return null;
                      },
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 14),
                      const _FieldLabel('Cliente'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _clientIdController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Codigo da propriedade ou operacao',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Informe o cliente.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    const _FieldLabel('Senha'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Sua senha',
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'A senha precisa ter pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: IzesColors.urgentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: theme.bodyMedium?.copyWith(
                            color: IzesColors.urgent,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isRegisterMode ? 'Criar conta' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _errorMessage = null;
                                });
                              },
                        child: Text(
                          _isRegisterMode ? 'Ja tenho conta' : 'Criar cadastro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}
