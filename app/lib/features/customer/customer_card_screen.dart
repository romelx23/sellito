import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/customer_session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../shared/loyalty_card_view.dart';
import 'customer_entry_screen.dart';

class CustomerCardScreen extends StatefulWidget {
  const CustomerCardScreen({super.key});

  @override
  State<CustomerCardScreen> createState() => _CustomerCardScreenState();
}

class _CustomerCardScreenState extends State<CustomerCardScreen> {
  Timer? _timer;
  bool _walletLoading = false;
  bool _qrVisible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<CustomerSession>().refreshQr();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openWallet() async {
    setState(() => _walletLoading = true);
    try {
      final url = await context.read<CustomerSession>().walletLink();
      if (!mounted) return;

      if (url == null) {
        showToast(context, 'No pudimos generar el pase', error: true);
        return;
      }

      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showToast(context, 'No se pudo abrir el pase', error: true);
      } else if (mounted && context.read<CustomerSession>().walletMode == 'mock') {
        showToast(context, 'Pase en modo demo (falta configurar Google)');
      }
    } catch (_) {
      if (mounted) showToast(context, 'No pudimos generar el pase', error: true);
    } finally {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  void _switchCard() {
    context.read<CustomerSession>().clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CustomerEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerSession>();
    final card = customer.card;
    final text = Theme.of(context).textTheme;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: customer.loading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.error ?? 'No encontramos tu tarjeta',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const CustomerEntryScreen()),
                        ),
                        child: const Text('Probar con otro código'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: customer.refreshQr,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Row(
                children: [
                  BrandAvatar(
                    name: card.businessName,
                    logoUrl: card.logoUrl,
                    color: card.brandColor,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge,
                        ),
                        Text('Tarjeta de fidelidad', style: text.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cambiar tarjeta',
                    onPressed: _switchCard,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 21),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LoyaltyCardView(
                style: card.style,
                businessName: card.businessName,
                logoUrl: card.logoUrl,
                programName: card.programName,
                rewardText: card.rewardText,
                stamps: card.stamps,
                required: card.stampsRequired,
                height: 225,
                showProgress: false,
              ),
              const SizedBox(height: 22),
              if (card.rewardReady)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SellaColors.amber.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SellaColors.amber.darken(.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: SellaColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¡Recompensa lista!', style: text.titleMedium),
                            Text(
                              'Mostrá esta pantalla en el local para canjearla.',
                              style: text.bodySmall?.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mostrá tu QR', style: text.titleLarge),
                              const SizedBox(height: 2),
                              Text(
                                'Se renueva solo cada 30 segundos.',
                                style: text.bodySmall?.copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(text: '${card.stamps}/${card.stampsRequired}'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => setState(() => _qrVisible = !_qrVisible),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: _qrVisible
                            ? Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: SellaColors.line),
                                ),
                                child: _Qr(
                                  token: card.qrToken,
                                  size: 240,
                                  color: card.brandColor,
                                ),
                              )
                            : Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  color: SellaColors.cream,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: SellaColors.line),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_2_rounded,
                                          size: 22, color: SellaColors.muted),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tocá para mostrar el QR',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: SellaColors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 1.6,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Añadir a Google Wallet',
                      icon: Icons.account_balance_wallet_rounded,
                      loading: _walletLoading,
                      color: SellaColors.ink,
                      onPressed: _openWallet,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'En iPhone la tarjeta funciona igual desde el navegador.',
                      style: text.bodySmall?.copyWith(fontSize: 10.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 20, color: card.brandColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Al completar la tarjeta', style: text.bodySmall?.copyWith(fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(card.rewardText, style: text.titleMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Hecho con Sella · tu tarjeta vive en este dispositivo',
                  style: text.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Qr extends StatelessWidget {
  const _Qr({required this.token, required this.size, required this.color});

  final String? token;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return QrImageView(
      data: token!,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color.darken(.1)),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: SellaColors.ink,
      ),
    );
  }
}
