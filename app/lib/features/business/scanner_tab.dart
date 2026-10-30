import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models.dart';
import 'card_sheet.dart';
import 'dashboard_tab.dart';

class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key, this.active = true});

  final bool active;

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final _code = TextEditingController();

  bool _busy = false;
  bool _manual = false;
  bool _searching = false;
  List<MerchantCard> _results = const [];
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCamera());
  }

  @override
  void didUpdateWidget(covariant ScannerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _syncCamera() async {
    try {
      if (!widget.active || _manual) {
        await _controller.stop();
      } else {
        await _controller.start();
      }
    } catch (_) {
      // Sin cámara disponible: queda la búsqueda manual.
    }
  }

  Future<void> _handleRaw(String raw) async {
    if (_busy || raw.trim().isEmpty) return;

    final session = context.read<Session>();
    setState(() => _busy = true);

    try {
      if (raw.startsWith('S1.')) {
        final result = await session.scan(raw);
        await _controller.stop();
        if (mounted) await _showResult(result);
      } else {
        final cards = await session.searchCards(raw.trim());
        if (!mounted) return;
        if (cards.length == 1) {
          await _showCard(cards.first);
        } else {
          showToast(context, 'Ese código no es un QR de Sella', error: true);
        }
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _syncCamera();
    }
  }

  Future<void> _search() async {
    final query = _code.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final cards = await context.read<Session>().searchCards(query);
      if (!mounted) return;
      setState(() {
        _results = cards;
        _searchError = cards.isEmpty ? 'No encontramos esa tarjeta' : null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _searchError = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _showResult(ScanResult result) async {
    if (!mounted) return;

    final session = context.read<Session>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final text = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: SellaColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: (result.completed ? SellaColors.amber : SellaColors.teal)
                      .withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.completed
                      ? Icons.card_giftcard_rounded
                      : Icons.check_rounded,
                  size: 34,
                  color: result.completed ? SellaColors.ink : SellaColors.teal,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                result.completed ? '¡Recompensa lista!' : 'Sello agregado',
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                result.card?.customerName ?? 'Cliente',
                style: text.bodySmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${result.stamps}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -2),
                  ),
                  Text(
                    ' / ${result.stampsRequired} sellos',
                    style: text.bodySmall?.copyWith(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: result.stampsRequired == 0
                      ? 0
                      : (result.stamps / result.stampsRequired).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: SellaColors.line,
                  valueColor: AlwaysStoppedAnimation(
                    result.completed ? SellaColors.amber.darken(.1) : SellaColors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SellaColors.line),
                ),
                child: Column(
                  children: [
                    Text(
                      result.completed ? 'ENTREGÁ LA RECOMPENSA' : 'PRÓXIMO PREMIO',
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.rewardText,
                      style: text.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Listo',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );

    await session.loadStats();
  }

  Future<void> _showCard(MerchantCard card) async {
    final changed = await showCustomerCardSheet(context, card);
    if (!changed || !mounted) return;

    final cards = await context.read<Session>().searchCards(_code.text.trim());
    if (mounted) setState(() => _results = cards);
  }
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Row(
            children: [
              Expanded(child: Text('Escanear', style: text.headlineMedium)),
              IconButton(
                tooltip: 'Linterna',
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on_rounded, size: 20),
              ),
            ],
          ),
          Text(
            'Apuntá al QR de la tarjeta del cliente. Se renueva cada 30 segundos.',
            style: text.bodySmall?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (!_manual)
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 330,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        final raw = capture.barcodes
                            .map((barcode) => barcode.rawValue)
                            .whereType<String>()
                            .firstOrNull;
                        if (raw != null) _handleRaw(raw);
                      },
                      errorBuilder: (context, error) => Container(
                        color: SellaColors.ink,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography_rounded,
                                color: Colors.white54, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'No pudimos abrir la cámara.\nUsá el ingreso manual de código.',
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withValues(alpha: .18), width: 40),
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
                        ),
                      ),
                    ),
                    if (_busy)
                      Container(
                        color: Colors.black.withValues(alpha: .35),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buscar por código', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Escribí el código de la tarjeta o el teléfono del cliente.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'CAFE-DEMO',
                      suffixIcon: IconButton(
                        onPressed: _searching ? null : _search,
                        icon: _searching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ),
                  if (_searchError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _searchError!,
                      style: const TextStyle(color: SellaColors.danger, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _manual = !_manual);
              _syncCamera();
            },
            icon: Icon(_manual ? Icons.qr_code_scanner_rounded : Icons.keyboard_rounded, size: 18),
            label: Text(_manual ? 'Usar la cámara' : 'Ingresar código a mano'),
          ),
          if (_manual && _results.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Resultados', style: text.titleLarge),
            const SizedBox(height: 10),
            ..._results.map(
              (card) => CustomerTile(card: card, onTap: () => _showCard(card)),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SellaColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 17, color: SellaColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cada QR sirve una sola vez: una captura de pantalla no permite sumar sellos.',
                    style: text.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
