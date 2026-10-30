import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models.dart';
import '../shared/loyalty_card_view.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onEditProgram});

  final VoidCallback onEditProgram;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<MerchantCard> _cards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<Session>();
    await session.loadStats();
    try {
      final cards = await session.searchCards('');
      if (mounted) setState(() => _cards = cards);
    } catch (_) {
      // El panel sigue siendo usable sin la lista.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _copyJoinLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) showToast(context, 'Link copiado');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final business = session.business;
    final program = session.program;
    final text = Theme.of(context).textTheme;

    if (business == null || program == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final joinUrl = '${Api.siteUrl}/j/${business.slug}';
    final stats = session.stats;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          children: [
            Row(
              children: [
                BrandAvatar(
                  name: business.name,
                  logoUrl: business.logoUrl,
                  color: business.brandColor,
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge,
                      ),
                      Text('Panel del negocio', style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await context.read<Session>().logout();
                    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'sellos hoy',
                    value: '${stats.stampsToday}',
                    icon: Icons.bolt_rounded,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'clientes',
                    value: '${stats.customers}',
                    icon: Icons.people_alt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'recompensas listas',
                    value: '${stats.rewardsReady}',
                    icon: Icons.card_giftcard_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'canjeadas',
                    value: '${stats.rewardsRedeemed}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SectionTitle(title: 'Tu tarjeta', action: 'Editar', onAction: widget.onEditProgram),
            GestureDetector(
              onTap: widget.onEditProgram,
              child: LoyaltyCardView(
                style: program.style,
                businessName: business.name,
                logoUrl: business.logoUrl,
                programName: program.name,
                rewardText: program.rewardText,
                stamps: 3,
                required: program.stampsRequired,
                height: 200,
                showProgress: false,
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: 'Link de inscripción'),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compartilo por WhatsApp o imprimí el QR. '
                    'El cliente se registra solo y recibe su tarjeta.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: SellaColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 17, color: SellaColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            joinUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyJoinLink(joinUrl),
                          icon: const Icon(Icons.content_copy_rounded, size: 16),
                          label: const Text('Copiar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(joinUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Abrir'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: 'Últimos clientes'),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_cards.isEmpty)
              SurfaceCard(
                child: Text(
                  'Todavía no hay clientes. Compartí el link de inscripción y aparecerán acá.',
                  style: text.bodySmall,
                ),
              )
            else
              ..._cards.take(5).map((card) => CustomerTile(card: card, dense: true)),
          ],
        ),
      ),
    );
  }
}

class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.card, this.dense = false, this.onTap});

  final MerchantCard card;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = card.stampsRequired == 0
        ? 0.0
        : (card.stamps / card.stampsRequired).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 8 : 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SellaColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SellaColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      card.customerName.isEmpty
                          ? '?'
                          : card.customerName.characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.code,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SellaColors.muted,
                          fontFamily: 'monospace',
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: SellaColors.cream,
                          valueColor: AlwaysStoppedAnimation(
                            card.rewardReady ? SellaColors.amber.darken(.1) : SellaColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (card.rewardReady)
                  StatusPill(text: 'LISTA', color: SellaColors.amber.darken(.25))
                else
                  Text(
                    '${card.stamps}/${card.stampsRequired}',
                    style: text.titleMedium?.copyWith(fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
