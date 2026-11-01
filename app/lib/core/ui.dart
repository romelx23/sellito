import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';

String? mediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '${Api.siteUrl}$path';
}

class SellaMark extends StatelessWidget {
  const SellaMark({super.key, this.size = 44, this.color = SellaColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isInk = color == SellaColors.ink;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * .3),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * .14),
          child: CustomPaint(
            painter: StampPainter(
              disc: isInk ? SellaColors.amber : Colors.white,
              ink: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sello postal: disco con dentado y una S en el centro. Misma forma que el ícono de la app.
class StampPainter extends CustomPainter {
  const StampPainter({required this.disc, required this.ink});

  final Color disc;
  final Color ink;

  static const _teeth = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .34;
    final tooth = size.shortestSide * .034;

    canvas.drawCircle(center, radius, Paint()..color = disc);

    final cut = Paint()..color = ink;
    for (var i = 0; i < _teeth; i++) {
      final angle = 2 * math.pi * i / _teeth;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(point, tooth, cut);
    }

    final painter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          color: SellaColors.ink,
          fontSize: size.shortestSide * .46,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(StampPainter old) => old.disc != disc || old.ink != ink;
}

class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.name,
    this.logoUrl,
    this.color = SellaColors.teal,
    this.size = 44,
  });

  final String name;
  final String? logoUrl;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl(logoUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(
                name.isEmpty ? 'S' : name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: color.onColor,
                  fontWeight: FontWeight.w800,
                  fontSize: size * .42,
                ),
              ),
            )
          : Image.network(url, fit: BoxFit.cover),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: color == null
          ? null
          : FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.border = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: border ? Border.all(color: SellaColors.line) : null,
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? SellaColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? SellaColors.ink : SellaColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 17,
              color: highlight ? SellaColors.amber : SellaColors.muted,
            ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: highlight ? Colors.white : SellaColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: highlight ? Colors.white70 : SellaColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    this.color = SellaColors.teal,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.darken(.08),
          letterSpacing: .2,
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? SellaColors.danger : SellaColors.ink,
      ),
    );
}
