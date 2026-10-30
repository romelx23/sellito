import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models.dart';
import 'card_sheet.dart';
import 'dashboard_tab.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final _query = TextEditingController();
  List<MerchantCard> _cards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load([String? query]) async {
    if (mounted) setState(() => _loading = true);
    try {
      final cards = await context.read<Session>().searchCards(query ?? _query.text);
      if (mounted) setState(() => _cards = cards);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(MerchantCard card) async {
    final changed = await showCustomerCardSheet(context, card);
    if (changed) await _load();
  }

  Future<void> _createManually() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final session = context.read<Session>();

    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Alta manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre del cliente'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Usalo cuando el cliente no pueda escanear el link.',
              style: TextStyle(fontSize: 11.5, color: SellaColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().length < 2) return;
              try {
                final code = await session.createCard(
                  name: name.text.trim(),
                  phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop(code);
              } on ApiException catch (e) {
                if (dialogContext.mounted) showToast(dialogContext, e.message, error: true);
              }
            },
            child: const Text('Crear tarjeta'),
          ),
        ],
      ),
    );

    name.dispose();
    phone.dispose();

    if (created != null) {
      await Clipboard.setData(ClipboardData(text: created));
      if (mounted) showToast(context, 'Tarjeta $created creada y copiada');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clientes', style: text.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Buscá por nombre, teléfono o código de tarjeta.',
                      style: text.bodySmall?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _load(),
                      onChanged: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Buscar…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _query.clear();
                                  _load('');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _load(),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                          children: [
                            if (_cards.isEmpty)
                              SurfaceCard(
                                child: Text(
                                  'No hay tarjetas todavía. Compartí el link o creá una desde el botón +.',
                                  style: text.bodySmall,
                                ),
                              )
                            else
                              ..._cards.map(
                                (card) => CustomerTile(
                                  card: card,
                                  onTap: () => _open(card),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: _createManually,
              backgroundColor: SellaColors.ink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Alta manual'),
            ),
          ),
        ],
      ),
    );
  }
}
