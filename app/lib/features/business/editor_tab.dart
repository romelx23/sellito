import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models.dart';
import '../shared/loyalty_card_view.dart';

class EditorTab extends StatefulWidget {
  const EditorTab({super.key});

  @override
  State<EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends State<EditorTab> {
  static const _palettes = <List<Color>>[
    [Color(0xFF0F766E), Color(0xFFF5C451)],
    [Color(0xFFA24B2A), Color(0xFFF2C14E)],
    [Color(0xFF1E3A5F), Color(0xFFE8B04B)],
    [Color(0xFF3F2D5C), Color(0xFFF0B7A4)],
    [Color(0xFF111827), Color(0xFF9AE6B4)],
    [Color(0xFFB91C1C), Color(0xFFFFE08A)],
    [Color(0xFF0B7285), Color(0xFF63E6BE)],
    [Color(0xFF7C2D12), Color(0xFFFCD34D)],
  ];

  static const _icons = ['circle', 'star', 'coffee', 'heart', 'check', 'paw', 'bolt'];

  static const _cooldowns = <int, String>{
    0: 'Sin límite',
    15: '15 min',
    30: '30 min',
    60: '1 hora',
    240: '4 horas',
    1440: '1 día',
  };

  late final TextEditingController _name;
  late final TextEditingController _reward;
  late int _stamps;
  late int _cooldown;
  late CardStyle _style;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final program = context.read<Session>().program!;
    _name = TextEditingController(text: program.name);
    _reward = TextEditingController(text: program.rewardText);
    _stamps = program.stampsRequired;
    _cooldown = program.cooldownMinutes;
    _style = program.style;
  }

  @override
  void dispose() {
    _name.dispose();
    _reward.dispose();
    super.dispose();
  }

  void _applyTemplate(String template) {
    final radius = switch (template) {
      'minimal' => 18.0,
      'bold' => 14.0,
      'retro' => 30.0,
      _ => 26.0,
    };
    final pattern = switch (template) {
      'minimal' => 'none',
      'bold' => 'grid',
      'retro' => 'waves',
      _ => 'dots',
    };
    setState(() {
      _style = _style.copyWith(template: template, cornerRadius: radius, pattern: pattern);
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 88,
    );
    if (file == null) return;
    if (!mounted) return;

    setState(() => _uploading = true);
    final session = context.read<Session>();
    try {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/png';
      await session.uploadLogo(bytes, mime);
      if (!mounted) return;
      showToast(context, 'Logo actualizado');
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      showToast(context, 'Poné un nombre al programa', error: true);
      return;
    }
    if (_reward.text.trim().length < 2) {
      showToast(context, 'Describí la recompensa', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<Session>().saveProgram(
            name: _name.text.trim(),
            rewardText: _reward.text.trim(),
            stampsRequired: _stamps,
            cooldownMinutes: _cooldown,
            style: _style,
          );
      if (mounted) showToast(context, 'Cambios guardados');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final business = session.business;
    final text = Theme.of(context).textTheme;

    if (business == null) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('Diseñá tu tarjeta', style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Todo se ve en vivo. Guardá cuando te guste el resultado.',
            style: text.bodySmall?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          LoyaltyCardView(
            style: _style,
            businessName: business.name,
            logoUrl: business.logoUrl,
            programName: _name.text.isEmpty ? 'Tu programa' : _name.text,
            rewardText: _reward.text.isEmpty ? 'Tu recompensa' : _reward.text,
            stamps: (_stamps * .62).round(),
            required: _stamps,
            height: 215,
          ),
          const SizedBox(height: 28),
          Text('IDENTIDAD', style: text.labelSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nombre del programa',
              hintText: 'Club Aurora',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reward,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Recompensa',
              hintText: 'Un café gratis',
            ),
          ),
          const SizedBox(height: 26),
          Text('MECÁNICA', style: text.labelSmall),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Sellos para el premio', style: text.titleMedium)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: business.brandColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_stamps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: business.brandColor,
                    thumbColor: business.brandColor,
                    overlayColor: business.brandColor.withValues(alpha: .12),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: _stamps.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    label: '$_stamps sellos',
                    onChanged: (value) => setState(() => _stamps = value.round()),
                  ),
                ),
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Un sello cada…', style: text.titleMedium),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cooldowns.entries.map((entry) {
                    final selected = _cooldown == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => setState(() => _cooldown = entry.key),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : SellaColors.ink,
                      ),
                      selectedColor: SellaColors.ink,
                      backgroundColor: SellaColors.cream,
                      side: BorderSide(color: selected ? SellaColors.ink : SellaColors.line),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('ESTILO', style: text.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['ticket', 'minimal', 'bold', 'retro'].map((template) {
              final selected = _style.template == template;
              return GestureDetector(
                onTap: () => _applyTemplate(template),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? SellaColors.ink : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? SellaColors.ink : SellaColors.line,
                    ),
                  ),
                  child: Text(
                    template[0].toUpperCase() + template.substring(1),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : SellaColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Color de la tarjeta', style: text.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palettes.map((pair) {
              final selected = _style.background.toARGB32() == pair[0].toARGB32();
              return GestureDetector(
                onTap: () => setState(() {
                  _style = _style.copyWith(
                    background: pair[0],
                    accent: pair[1],
                    foreground: pair[0].onColor,
                  );
                }),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: pair[0],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? SellaColors.ink : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 18, color: pair[1])
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text('Ícono del sello', style: text.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _icons.map((icon) {
              final selected = _style.stampIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _style = _style.copyWith(stampIcon: icon)),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? business.brandColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? business.brandColor : SellaColors.line),
                  ),
                  child: Icon(
                    stampIconData(icon),
                    size: 20,
                    color: selected ? Colors.white : SellaColors.muted,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text('Textura de fondo', style: text.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['none', 'dots', 'grid', 'waves'].map((pattern) {
              final selected = _style.pattern == pattern;
              final labels = {
                'none': 'Lisa',
                'dots': 'Puntos',
                'grid': 'Grilla',
                'waves': 'Ondas',
              };
              return ChoiceChip(
                label: Text(labels[pattern]!),
                selected: selected,
                onSelected: (_) => setState(() => _style = _style.copyWith(pattern: pattern)),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : SellaColors.ink,
                ),
                selectedColor: SellaColors.ink,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? SellaColors.ink : SellaColors.line),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                BrandAvatar(
                  name: business.name,
                  logoUrl: business.logoUrl,
                  color: business.brandColor,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logo del negocio', style: text.titleMedium),
                      Text('PNG o JPG, cuadrado', style: text.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _uploading ? null : _pickLogo,
                  child: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cambiar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Guardar cambios',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
            color: business.brandColor,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Los clientes ven los cambios en su próxima actualización.',
              style: text.bodySmall?.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
