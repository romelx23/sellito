import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models.dart';

IconData stampIconData(String name) {
  switch (name) {
    case 'star':
      return Icons.star_rounded;
    case 'coffee':
      return Icons.local_cafe_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    case 'check':
      return Icons.check_rounded;
    case 'paw':
      return Icons.pets_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    default:
      return Icons.circle;
  }
}

class StampGrid extends StatelessWidget {
  const StampGrid({
    super.key,
    required this.stamps,
    required this.required,
    required this.filled,
    required this.empty,
    required this.icon,
    this.cellSize = 30,
    this.spacing = 7,
    this.maxColumns = 8,
  });

  final int stamps;
  final int required;
  final Color filled;
  final Color empty;
  final IconData icon;
  final double cellSize;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final iconSize = cellSize * .52;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(required, (index) {
        final on = index < stamps;
        return Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? filled : empty,
            border: Border.all(
              color: on ? filled : filled.withValues(alpha: .35),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: on ? _contrast(filled) : filled.withValues(alpha: .35),
            ),
          ),
        );
      }),
    );
  }

  Color _contrast(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : SellaColors.ink;
}

class LoyaltyCardView extends StatelessWidget {
  const LoyaltyCardView({
    super.key,
    required this.style,
    required this.programName,
    required this.rewardText,
    required this.businessName,
    required this.stamps,
    required this.required,
    this.logoUrl,
    this.height = 230,
    this.showProgress = true,
    this.compact = false,
  });

  final CardStyle style;
  final String programName;
  final String rewardText;
  final String businessName;
  final int stamps;
  final int required;
  final String? logoUrl;
  final double height;
  final bool showProgress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(style.cornerRadius);
    final fg = style.foreground;
    final url = mediaUrl(logoUrl);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: style.background.withValues(alpha: .3),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      style.background.lighten(.06),
                      style.background,
                      style.background.darken(.22),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _PatternPainter(style.pattern, fg)),
            ),
            Positioned(
              right: -50,
              top: -60,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fg.withValues(alpha: .05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (url != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: fg.withValues(alpha: .8),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.storefront_rounded,
                          size: 15,
                          color: fg.withValues(alpha: .7),
                        ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          businessName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg.withValues(alpha: .82),
                            fontSize: compact ? 8.5 : 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'MIEMBRO',
                          style: TextStyle(
                            color: fg.withValues(alpha: .9),
                            fontSize: compact ? 7 : 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    programName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: compact ? 17 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  StampGrid(
                    stamps: stamps,
                    required: required,
                    filled: fg,
                    empty: fg.withValues(alpha: .08),
                    icon: stampIconData(style.stampIcon),
                    cellSize: compact ? 20 : (required > 10 ? 24 : 30),
                    spacing: compact ? 5 : 7,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (showProgress)
                        Text(
                          '$stamps / $required',
                          style: TextStyle(
                            color: fg,
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                      if (showProgress) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rewardText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: fg.withValues(alpha: .72),
                            fontSize: compact ? 8.5 : 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.pattern, this.color);

  final String pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .13);

    switch (pattern) {
      case 'dots':
        for (double x = 14; x < size.width; x += 18) {
          for (double y = 14; y < size.height; y += 18) {
            canvas.drawCircle(Offset(x, y), 1.1, paint);
          }
        }
        break;

      case 'grid':
        final stroke = Paint()
          ..color = color.withValues(alpha: .08)
          ..strokeWidth = 1;
        for (double x = 0; x < size.width; x += 26) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
        }
        for (double y = 0; y < size.height; y += 26) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
        }
        break;

      case 'waves':
        final stroke = Paint()
          ..color = color.withValues(alpha: .1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        for (double offset = 0; offset < size.height + 40; offset += 22) {
          final path = Path()..moveTo(0, offset);
          for (double x = 0; x <= size.width; x += 6) {
            path.lineTo(x, offset + math.sin((x / 34) + offset / 40) * 5);
          }
          canvas.drawPath(path, stroke);
        }
        break;

      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.color != color;
}
