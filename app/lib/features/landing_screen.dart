import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/customer_session.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models.dart';
import 'auth/login_screen.dart';
import 'business/business_shell.dart';
import 'customer/customer_card_screen.dart';
import 'customer/customer_entry_screen.dart';
import 'shared/loyalty_card_view.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _demoStyle = CardStyle(
    template: 'ticket',
    stampIcon: 'coffee',
    pattern: 'dots',
    background: Color(0xFFA24B2A),
    foreground: Color(0xFFFFF7ED),
    accent: Color(0xFFF2C14E),
    cornerRadius: 26,
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final customer = context.watch<CustomerSession>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -110,
            child: _Blob(color: SellaColors.teal.withValues(alpha: .07), size: 320),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: _Blob(color: SellaColors.amber.withValues(alpha: .22), size: 300),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SellaMark(size: 38),
                          const SizedBox(width: 10),
                          Text(
                            'Sella',
                            style: text.titleLarge?.copyWith(fontSize: 19, letterSpacing: -.4),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: SellaColors.line),
                            ),
                            child: Text(
                              'DEMO',
                              style: text.labelSmall?.copyWith(fontSize: 9.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Sellos que\n'),
                            TextSpan(
                              text: 'vuelven ',
                              style: const TextStyle(color: SellaColors.teal),
                            ),
                            const TextSpan(text: 'clientes.'),
                          ],
                        ),
                        style: text.displaySmall?.copyWith(fontSize: 42),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tarjetas de fidelidad personalizables para tu negocio. '
                        'Sin apps que instalar, sin comisiones y con Google Wallet.',
                        style: text.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          color: SellaColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Transform.rotate(
                        angle: -0.022,
                        child: LoyaltyCardView(
                          style: _demoStyle,
                          businessName: 'Café Aurora',
                          programName: 'Club Aurora',
                          rewardText: 'Un flat white gratis',
                          stamps: 5,
                          required: 8,
                          height: 205,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (session.isLoggedIn) ...[
                        PrimaryButton(
                          label: 'Panel de ${session.business?.name ?? 'mi negocio'}',
                          icon: Icons.storefront_rounded,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BusinessShell()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => context.read<Session>().logout(),
                          child: const Text('Cerrar sesión del negocio'),
                        ),
                      ] else ...[
                        PrimaryButton(
                          label: 'Soy negocio',
                          icon: Icons.storefront_rounded,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            final hasCard = customer.card != null;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => hasCard
                                    ? const CustomerCardScreen()
                                    : const CustomerEntryScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.confirmation_number_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                customer.card != null
                                    ? 'Volver a mi tarjeta'
                                    : 'Tengo una tarjeta',
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SellaColors.line),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: SellaColors.muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Demo: demo@sella.app · demo1234 · tarjeta CAFE-DEMO',
                                style: text.bodySmall?.copyWith(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Text(
                          'Código abierto · Flutter + Node + Google Wallet',
                          style: text.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
