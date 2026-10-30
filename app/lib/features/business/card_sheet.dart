import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models.dart';

/// Devuelve true si se agregó un sello o se canjeó una recompensa.
Future<bool> showCustomerCardSheet(BuildContext context, MerchantCard card) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final text = Theme.of(sheetContext).textTheme;
      final session = sheetContext.read<Session>();
      final progress = card.stampsRequired == 0
          ? 0.0
          : (card.stamps / card.stampsRequired).clamp(0.0, 1.0);

      Future<void> run(Future<void> Function() action) async {
        Navigator.of(sheetContext).pop(true);
        try {
          await action();
          if (context.mounted) showToast(context, 'Listo');
        } on ApiException catch (e) {
          if (context.mounted) showToast(context, e.message, error: true);
        }
      }

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
            const SizedBox(height: 24),
            Text(card.customerName, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${card.code} · ${card.programName}',
              style: text.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${card.stamps}',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  ' / ${card.stampsRequired} sellos',
                  style: text.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: SellaColors.line,
                valueColor: AlwaysStoppedAnimation(
                  card.rewardReady ? SellaColors.amber.darken(.1) : SellaColors.teal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (card.customerPhone != null && card.customerPhone!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_rounded, size: 13, color: SellaColors.muted),
                  const SizedBox(width: 6),
                  Text(card.customerPhone!, style: text.bodySmall),
                ],
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
                    card.rewardReady ? 'RECOMPENSA PENDIENTE' : 'RECOMPENSA',
                    style: text.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(card.rewardText, style: text.titleMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (card.rewardReady)
              PrimaryButton(
                label: 'Canjear recompensa',
                icon: Icons.redeem_rounded,
                onPressed: () => run(() => session.redeem(card.id)),
              )
            else
              PrimaryButton(
                label: 'Agregar sello',
                icon: Icons.add_rounded,
                onPressed: () => run(() => session.addStamp(card.id)),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}
