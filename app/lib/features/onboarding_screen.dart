import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../core/ui.dart';
import '../models.dart';
import 'landing_screen.dart';
import 'shared/loyalty_card_view.dart';

/// Tres pantallas que explican Sella la primera vez que se abre la app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _doneKey = 'sella_onboarding_done';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_doneKey) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _lastPage = 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingScreen()));
  }

  void _next() {
    if (_page == _lastPage) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isLast = _page == _lastPage;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const SellaMark(size: 34),
                  const SizedBox(width: 10),
                  Text('Sella', style: text.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: isLast ? null : _finish,
                    child: const Text('Saltar'),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: const [
                    _Slide(
                      title: 'Tu tarjeta, con tu marca',
                      body:
                          'Elegís colores, ícono de sello, meta y recompensa. '
                          'Tu cliente ve tu negocio, no el de una plataforma.',
                      visual: _CardVisual(),
                    ),
                    _Slide(
                      title: 'Sumar es escanear',
                      body:
                          'El cliente muestra su QR en el mostrador. El QR cambia cada 30 segundos, '
                          'así que una captura de pantalla no sirve.',
                      visual: _QrVisual(),
                    ),
                    _Slide(
                      title: 'Sin instalar y sin comisiones',
                      body:
                          'El cliente se une desde el navegador y puede añadir la tarjeta a Google Wallet. '
                          'Vos no pagás comisión por cada canje.',
                      visual: _WalletVisual(),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i <= _lastPage; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? SellaColors.teal : SellaColors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: isLast ? 'Empezar' : 'Siguiente',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.body, required this.visual});

  final String title;
  final String body;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        visual,
        const SizedBox(height: 32),
        Text(title, style: text.headlineMedium),
        const SizedBox(height: 10),
        Text(
          body,
          style: text.bodyMedium?.copyWith(
            fontSize: 15,
            color: SellaColors.muted,
          ),
        ),
      ],
    );
  }
}

class _CardVisual extends StatelessWidget {
  const _CardVisual();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: const LoyaltyCardView(
        style: CardStyle(
          template: 'retro',
          stampIcon: 'circle',
          pattern: 'waves',
          background: Color(0xFF3F2D5C),
          foreground: Color(0xFFFFF4EC),
          accent: Color(0xFFF0B7A4),
          cornerRadius: 30,
        ),
        businessName: 'Cafetería Tomillo',
        programName: 'Tomillo Club',
        rewardText: 'Una medialuna gratis',
        stamps: 6,
        required: 10,
        height: 210,
      ),
    );
  }
}

class _QrVisual extends StatelessWidget {
  const _QrVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SellaColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SellaColors.amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: SellaColors.ink,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.arrow_forward_rounded, color: SellaColors.muted),
          const SizedBox(width: 14),
          const Icon(
            Icons.qr_code_2_rounded,
            size: 120,
            color: SellaColors.ink,
          ),
        ],
      ),
    );
  }
}

class _WalletVisual extends StatelessWidget {
  const _WalletVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SellaColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIN APPS QUE INSTALAR',
            style: const TextStyle(
              color: SellaColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const Text(
            '0%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'de comisión por canje',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
