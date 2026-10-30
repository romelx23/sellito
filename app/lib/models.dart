import 'package:flutter/material.dart';

Color colorFromHex(String? value, Color fallback) {
  if (value == null) return fallback;
  final hex = value.replaceAll('#', '').trim();
  if (hex.length != 6) return fallback;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}

String colorToHex(Color color) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${argb.substring(2).toUpperCase()}';
}

class CardStyle {
  final String template;
  final String stampIcon;
  final String pattern;
  final Color background;
  final Color foreground;
  final Color accent;
  final double cornerRadius;
  final bool showLogo;

  const CardStyle({
    required this.template,
    required this.stampIcon,
    required this.pattern,
    required this.background,
    required this.foreground,
    required this.accent,
    this.cornerRadius = 24,
    this.showLogo = true,
  });

  static const fallback = CardStyle(
    template: 'ticket',
    stampIcon: 'circle',
    pattern: 'dots',
    background: Color(0xFF0F766E),
    foreground: Colors.white,
    accent: Color(0xFFF5C451),
  );

  factory CardStyle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return fallback;
    return CardStyle(
      template: json['template'] as String? ?? fallback.template,
      stampIcon: json['stampIcon'] as String? ?? fallback.stampIcon,
      pattern: json['pattern'] as String? ?? fallback.pattern,
      background: colorFromHex(json['background'] as String?, fallback.background),
      foreground: colorFromHex(json['foreground'] as String?, fallback.foreground),
      accent: colorFromHex(json['accent'] as String?, fallback.accent),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? fallback.cornerRadius,
      showLogo: json['showLogo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'template': template,
        'stampIcon': stampIcon,
        'pattern': pattern,
        'background': colorToHex(background),
        'foreground': colorToHex(foreground),
        'accent': colorToHex(accent),
        'cornerRadius': cornerRadius,
        'showLogo': showLogo,
      };

  CardStyle copyWith({
    String? template,
    String? stampIcon,
    String? pattern,
    Color? background,
    Color? foreground,
    Color? accent,
    double? cornerRadius,
    bool? showLogo,
  }) {
    return CardStyle(
      template: template ?? this.template,
      stampIcon: stampIcon ?? this.stampIcon,
      pattern: pattern ?? this.pattern,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      accent: accent ?? this.accent,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showLogo: showLogo ?? this.showLogo,
    );
  }
}

class Business {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final Color brandColor;

  const Business({
    required this.id,
    required this.name,
    required this.slug,
    required this.brandColor,
    this.logoUrl,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        logoUrl: json['logo_url'] as String?,
        brandColor: colorFromHex(json['brand_color'] as String?, const Color(0xFF0F766E)),
      );
}

class Program {
  final String id;
  final String name;
  final String? description;
  final String rewardText;
  final int stampsRequired;
  final int cooldownMinutes;
  final int maxPerDay;
  final CardStyle style;
  final bool active;

  const Program({
    required this.id,
    required this.name,
    required this.rewardText,
    required this.stampsRequired,
    required this.style,
    this.description,
    this.cooldownMinutes = 0,
    this.maxPerDay = 0,
    this.active = true,
  });

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        rewardText: json['reward_text'] as String,
        stampsRequired: (json['stamps_required'] as num).toInt(),
        cooldownMinutes: (json['cooldown_minutes'] as num?)?.toInt() ?? 0,
        maxPerDay: (json['max_per_day'] as num?)?.toInt() ?? 0,
        style: CardStyle.fromJson(json['style'] as Map<String, dynamic>?),
        active: json['active'] as bool? ?? true,
      );

  Program copyWith({
    String? name,
    String? description,
    String? rewardText,
    int? stampsRequired,
    int? cooldownMinutes,
    int? maxPerDay,
    CardStyle? style,
    bool? active,
  }) {
    return Program(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      rewardText: rewardText ?? this.rewardText,
      stampsRequired: stampsRequired ?? this.stampsRequired,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      style: style ?? this.style,
      active: active ?? this.active,
    );
  }
}

class Stats {
  final int customers;
  final int cards;
  final int stampsToday;
  final int rewardsReady;
  final int rewardsRedeemed;

  const Stats({
    this.customers = 0,
    this.cards = 0,
    this.stampsToday = 0,
    this.rewardsReady = 0,
    this.rewardsRedeemed = 0,
  });

  factory Stats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Stats();
    return Stats(
      customers: (json['customers'] as num?)?.toInt() ?? 0,
      cards: (json['cards'] as num?)?.toInt() ?? 0,
      stampsToday: (json['stampsToday'] as num?)?.toInt() ?? 0,
      rewardsReady: (json['rewardsReady'] as num?)?.toInt() ?? 0,
      rewardsRedeemed: (json['rewardsRedeemed'] as num?)?.toInt() ?? 0,
    );
  }
}

class MerchantCard {
  final String id;
  final String code;
  final int stamps;
  final int stampsRequired;
  final String status;
  final String rewardText;
  final String programName;
  final String customerName;
  final String? customerPhone;

  const MerchantCard({
    required this.id,
    required this.code,
    required this.stamps,
    required this.stampsRequired,
    required this.status,
    required this.rewardText,
    required this.programName,
    required this.customerName,
    this.customerPhone,
  });

  bool get rewardReady => status == 'reward_ready';

  factory MerchantCard.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    return MerchantCard(
      id: json['id'] as String,
      code: json['code'] as String,
      stamps: (json['stamps'] as num).toInt(),
      stampsRequired: (json['stampsRequired'] as num?)?.toInt() ?? 8,
      status: json['status'] as String? ?? 'active',
      rewardText: json['rewardText'] as String? ?? '',
      programName: json['programName'] as String? ?? '',
      customerName: customer['name'] as String? ?? 'Cliente',
      customerPhone: customer['phone'] as String?,
    );
  }
}

class PublicCard {
  final String code;
  final int stamps;
  final int stampsRequired;
  final String status;
  final String rewardText;
  final String customerName;
  final String programName;
  final String businessName;
  final String? logoUrl;
  final Color brandColor;
  final CardStyle style;
  final String? qrToken;

  const PublicCard({
    required this.code,
    required this.stamps,
    required this.stampsRequired,
    required this.status,
    required this.rewardText,
    required this.customerName,
    required this.programName,
    required this.businessName,
    required this.brandColor,
    required this.style,
    this.logoUrl,
    this.qrToken,
  });

  bool get rewardReady => status == 'reward_ready';

  factory PublicCard.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    final program = json['program'] as Map<String, dynamic>? ?? {};
    final business = json['business'] as Map<String, dynamic>? ?? {};
    final qr = json['qr'] as Map<String, dynamic>?;

    return PublicCard(
      code: json['code'] as String,
      stamps: (json['stamps'] as num).toInt(),
      stampsRequired: (json['stampsRequired'] as num).toInt(),
      status: json['status'] as String? ?? 'active',
      rewardText: json['rewardText'] as String? ?? '',
      customerName: customer['name'] as String? ?? 'Cliente',
      programName: program['name'] as String? ?? '',
      businessName: business['name'] as String? ?? '',
      logoUrl: business['logoUrl'] as String?,
      brandColor: colorFromHex(business['brandColor'] as String?, const Color(0xFF0F766E)),
      style: CardStyle.fromJson(program['style'] as Map<String, dynamic>?),
      qrToken: qr?['token'] as String?,
    );
  }
}

class ScanResult {
  final bool completed;
  final bool alreadyStamped;
  final int stamps;
  final int stampsRequired;
  final String rewardText;
  final MerchantCard? card;

  const ScanResult({
    required this.completed,
    required this.alreadyStamped,
    required this.stamps,
    required this.stampsRequired,
    required this.rewardText,
    this.card,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        completed: json['completed'] as bool? ?? false,
        alreadyStamped: json['alreadyStamped'] as bool? ?? json['duplicate'] as bool? ?? false,
        stamps: (json['stamps'] as num?)?.toInt() ?? 0,
        stampsRequired: (json['stampsRequired'] as num?)?.toInt() ?? 8,
        rewardText: json['rewardText'] as String? ?? '',
        card: json['card'] is Map<String, dynamic>
            ? MerchantCard.fromJson(json['card'] as Map<String, dynamic>)
            : null,
      );
}
