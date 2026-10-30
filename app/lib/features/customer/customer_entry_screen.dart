import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/customer_session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'customer_card_screen.dart';

class CustomerEntryScreen extends StatefulWidget {
  const CustomerEntryScreen({super.key});

  @override
  State<CustomerEntryScreen> createState() => _CustomerEntryScreenState();
}

class _CustomerEntryScreenState extends State<CustomerEntryScreen> {
  final _code = TextEditingController();
  final _slug = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  bool _joinMode = false;
  bool _loading = false;
  bool _consent = true;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _slug.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _openCard() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Escribí el código de tu tarjeta');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await context.read<CustomerSession>().load(code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerCardScreen()),
      );
    } else {
      setState(() => _error = context.read<CustomerSession>().error);
    }
  }

  Future<void> _join() async {
    if (_slug.text.trim().isEmpty) {
      setState(() => _error = 'Poné el nombre del negocio o su link');
      return;
    }
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Necesitamos tu nombre');
      return;
    }
    if (_phone.text.trim().length < 6) {
      setState(() => _error = 'Necesitamos un teléfono de contacto');
      return;
    }
    if (!_consent) {
      setState(() => _error = 'Necesitamos tu consentimiento para guardar los datos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final slug = _slug.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^.*\/j\/'), '')
        .replaceAll(RegExp(r'/$'), '');

    final error = await context.read<CustomerSession>().join(
          slug: slug,
          name: _name.text,
          phone: _phone.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerCardScreen()),
      );
    } else {
      setState(() => _error = error);
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
                Text(
                  _joinMode ? 'Sumate a un\nnegocio.' : 'Tu tarjeta,\nen el bolsillo.',
                  style: text.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  _joinMode
                      ? 'Pegá el link que te compartió el negocio o escribí su nombre.'
                      : 'Ingresá el código que te dio el negocio. No necesitás contraseña.',
                  style: text.bodyMedium?.copyWith(color: SellaColors.muted),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SellaColors.line),
                  ),
                  child: Row(
                    children: [
                      _Toggle(
                        label: 'Ya tengo',
                        selected: !_joinMode,
                        onTap: () => setState(() {
                          _joinMode = false;
                          _error = null;
                        }),
                      ),
                      _Toggle(
                        label: 'Quiero unirme',
                        selected: _joinMode,
                        onTap: () => setState(() {
                          _joinMode = true;
                          _error = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_joinMode) ...[
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _openCard(),
                    decoration: const InputDecoration(
                      labelText: 'Código de tarjeta',
                      hintText: 'CAFE-DEMO',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lo encontrás debajo del QR en la web del negocio.',
                    style: text.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ] else ...[
                  TextField(
                    controller: _slug,
                    decoration: const InputDecoration(
                      labelText: 'Link o nombre del negocio',
                      hintText: 'cafe-aurora',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Tu nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'WhatsApp o teléfono'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consent,
                        activeColor: SellaColors.teal,
                        onChanged: (value) => setState(() => _consent = value ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Acepto que el negocio guarde mi nombre y teléfono para gestionar mi tarjeta.',
                            style: text.bodySmall?.copyWith(fontSize: 11.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
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
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _joinMode ? 'Crear mi tarjeta' : 'Ver mi tarjeta',
                  loading: _loading,
                  onPressed: _joinMode ? _join : _openCard,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Sin instalar nada. Tu tarjeta también funciona en el navegador.',
                    style: text.bodySmall?.copyWith(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? SellaColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : SellaColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
