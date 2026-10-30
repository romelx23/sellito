import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../business/business_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _business = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _palette = [
    Color(0xFF0F766E),
    Color(0xFFA24B2A),
    Color(0xFF1E3A5F),
    Color(0xFF3F2D5C),
    Color(0xFF111827),
    Color(0xFFB91C1C),
  ];

  Color _color = _palette.first;

  @override
  void dispose() {
    _business.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_business.text.trim().length < 2) {
      setState(() => _error = 'Poné el nombre de tu negocio');
      return;
    }
    if (_email.text.trim().length < 5) {
      setState(() => _error = 'Revisá el email');
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = 'La contraseña necesita 6 caracteres o más');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<Session>().register(
            businessName: _business.text,
            name: _name.text.isEmpty ? _business.text : _name.text,
            email: _email.text,
            password: _password.text,
            brandColor: _color,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BusinessShell()),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Creá tu tarjeta\nen 2 minutos.', style: text.displaySmall),
                const SizedBox(height: 10),
                Text(
                  'Después podés cambiar colores, logo, sellos y recompensa cuando quieras.',
                  style: text.bodyMedium?.copyWith(color: SellaColors.muted),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _business,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                    hintText: 'Café Aurora',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre',
                    hintText: 'Lucía',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'hola@tunegocio.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 20),
                Text('COLOR DE MARCA', style: text.labelSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _palette.map((color) {
                    final selected = color.toARGB32() == _color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? SellaColors.ink : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SellaColors.danger.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: SellaColors.danger, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Crear mi negocio',
                  loading: _loading,
                  onPressed: _submit,
                  color: _color,
                ),
                const SizedBox(height: 12),
                Text(
                  'Al crear la cuenta aceptás que guardemos los datos de tus clientes '
                  'solo para gestionar la tarjeta.',
                  style: text.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
