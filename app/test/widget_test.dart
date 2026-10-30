import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sella_app/core/theme.dart';
import 'package:sella_app/features/shared/loyalty_card_view.dart';
import 'package:sella_app/models.dart';

void main() {
  group('LoyaltyCardView', () {
    testWidgets('muestra negocio, programa y progreso', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSellaTheme(),
          home: Scaffold(
            body: LoyaltyCardView(
              style: CardStyle.fallback,
              businessName: 'Café Aurora',
              programName: 'Club Aurora',
              rewardText: 'Un flat white gratis',
              stamps: 5,
              required: 8,
            ),
          ),
        ),
      );

      expect(find.text('CAFÉ AURORA'), findsOneWidget);
      expect(find.text('Club Aurora'), findsOneWidget);
      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('Un flat white gratis'), findsOneWidget);
    });

    testWidgets('dibuja un sello por cada casilla', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSellaTheme(),
          home: Scaffold(
            body: LoyaltyCardView(
              style: CardStyle.fallback,
              businessName: 'Barbería Norte',
              programName: 'Corte Club',
              rewardText: 'Un corte gratis',
              stamps: 3,
              required: 6,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.circle), findsNWidgets(6));
    });
  });

  group('Modelos', () {
    test('CardStyle conserva los colores al serializar', () {
      const style = CardStyle(
        template: 'bold',
        stampIcon: 'star',
        pattern: 'grid',
        background: Color(0xFF1E3A5F),
        foreground: Colors.white,
        accent: Color(0xFFE8B04B),
        cornerRadius: 18,
      );

      final restored = CardStyle.fromJson(style.toJson());

      expect(restored.template, 'bold');
      expect(restored.stampIcon, 'star');
      expect(restored.background.toARGB32(), style.background.toARGB32());
      expect(restored.foreground.toARGB32(), style.foreground.toARGB32());
      expect(restored.cornerRadius, 18);
    });

    test('Program lee el estilo anidado del backend', () {
      final program = Program.fromJson({
        'id': 'p1',
        'name': 'Club Aurora',
        'description': 'Cada visita suma',
        'reward_text': 'Un café gratis',
        'stamps_required': 8,
        'cooldown_minutes': 30,
        'max_per_day': 0,
        'active': true,
        'style': CardStyle.fallback.toJson(),
      });

      expect(program.name, 'Club Aurora');
      expect(program.stampsRequired, 8);
      expect(program.cooldownMinutes, 30);
      expect(program.style.stampIcon, 'circle');
    });

    test('PublicCard expone el QR y la recompensa', () {
      final card = PublicCard.fromJson({
        'code': 'CAFE-DEMO',
        'stamps': 3,
        'stampsRequired': 8,
        'status': 'active',
        'rewardText': 'Un café gratis',
        'customer': {'name': 'Ana P.'},
        'program': {'name': 'Club Aurora', 'style': CardStyle.fallback.toJson()},
        'business': {'name': 'Café Aurora', 'brandColor': '#A24B2A'},
        'qr': {'token': 'S1.abc.def'},
      });

      expect(card.code, 'CAFE-DEMO');
      expect(card.rewardReady, isFalse);
      expect(card.qrToken, 'S1.abc.def');
      expect(card.brandColor.toARGB32(), const Color(0xFFA24B2A).toARGB32());
    });
  });
}
