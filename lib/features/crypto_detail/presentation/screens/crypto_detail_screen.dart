import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_provider.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_state.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/widgets/week_line_chart.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/watchlist/presentation/providers/favorites_provider.dart';
/// Fiche crypto moderne selon le design épuré adapté aux fonctionnalités réelles.
class CryptoDetailScreen extends ConsumerWidget {
  const CryptoDetailScreen({super.key, this.coinId = 'bitcoin', this.crypto});

  final String coinId;
  final Crypto? crypto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartState = ref.watch(priceHistoryProvider(coinId));
    final selected = crypto;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _DetailHeader(
                  crypto: selected,
                  coinId: coinId,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Prix et Variation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected == null
                                      ? r'$112 840,52'
                                      : formatDetailPrice(selected.currentPrice),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _ChangePill(
                                  change: selected?.priceChangePercentage24h,
                                  useMockup: selected == null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Carte du Graphique 7 jours (données réelles CoinGecko)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.cardBorder, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Historique (7 derniers jours)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '7D',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ChartSection(
                              state: chartState,
                              onRetry: () => ref
                                  .read(priceHistoryProvider(coinId).notifier)
                                  .retry(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Grille de statistiques
                      const Text(
                        'Statistiques du marché',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatsGrid(crypto: selected),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends ConsumerWidget {
  const _DetailHeader({this.crypto, required this.coinId});

  final Crypto? crypto;
  final String coinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = crypto;
    final name = selected?.name ?? 'Bitcoin';
    final symbol = selected?.symbol ?? 'btc';
    final letter = selected == null
        ? 'B'
        : (selected.symbol.isNotEmpty
            ? selected.symbol[0].toUpperCase()
            : '?');
    final markColor = selected == null
        ? AppColors.bitcoin
        : _markColorFor(selected.symbol);
    final rank = selected == null ? 1 : selected.marketCapRank;
    final effectiveId = selected?.id ?? coinId;

    final isFavorite = ref.watch(
      favoritesProvider.select((Set<String> ids) => ids.contains(effectiveId)),
    );

    return Row(
      children: [
        InkWell(
          onTap: () {
            final navigator = Navigator.maybeOf(context);
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              _CoinMark(letter: letter, color: markColor),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${symbol.toUpperCase()} / USD',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (rank != null) ...[
                const SizedBox(width: 8),
                _RankBadge(label: 'Rang $rank'),
              ],
            ],
          ),
        ),
        IconButton(
          key: Key('favorite-toggle-detail-$effectiveId'),
          onPressed: () => ref
              .read(favoritesProvider.notifier)
              .toggleFavorite(effectiveId),
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? AppColors.star : AppColors.textSecondary,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.state, required this.onRetry});

  final PriceHistoryState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PriceHistoryLoading() => const SizedBox(
          height: 196,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      PriceHistoryError(:final message) => SizedBox(
          height: 196,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.loss, size: 36),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      PriceHistoryLoaded(:final points) => WeekLineChart(points: points),
    };
  }
}

class _CoinMark extends StatelessWidget {
  const _CoinMark({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.rankBadge,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({this.change, this.useMockup = false});

  final double? change;
  final bool useMockup;

  @override
  Widget build(BuildContext context) {
    if (!useMockup && change == null) {
      return const SizedBox.shrink();
    }

    final value = useMockup ? 2.4 : change!;
    final isPositive = value >= 0;
    final label = useMockup
        ? '+2,4 % sur 24 h'
        : formatDetailChange(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.gainPill : AppColors.lossPill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isPositive ? AppColors.gain : AppColors.loss,
            size: 18,
          ),
          Text(
            label,
            style: TextStyle(
              color: isPositive ? AppColors.gain : AppColors.loss,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({this.crypto});

  final Crypto? crypto;

  @override
  Widget build(BuildContext context) {
    final selected = crypto;
    final high = selected == null
        ? r'$114 120'
        : formatDetailStat(selected.high24h);
    final low = selected == null
        ? r'$109 480'
        : formatDetailStat(selected.low24h);
    final volume = selected == null
        ? r'$38,2 Md'
        : formatDetailCompact(selected.volume24h);
    final cap = selected == null
        ? r'$2 230 Md'
        : formatDetailCompact(selected.marketCap);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(label: 'Plus haut 24 h', value: high, icon: Icons.trending_up_rounded),
        _StatCard(label: 'Plus bas 24 h', value: low, icon: Icons.trending_down_rounded),
        _StatCard(label: 'Volume 24 h', value: volume, icon: Icons.bar_chart_rounded),
        _StatCard(label: 'Capitalisation', value: cap, icon: Icons.pie_chart_outline_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: AppColors.textTertiary),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

Color _markColorFor(String symbol) {
  const palette = [
    Color(0xFFF7931A),
    Color(0xFF627EEA),
    Color(0xFF26A17B),
    Color(0xFFF0B90B),
    Color(0xFF9945FF),
  ];
  return palette[symbol.hashCode.abs() % palette.length];
}

String formatDetailPrice(double value) {
  final parts = value.abs().toStringAsFixed(2).split('.');
  final grouped = _groupThousands(parts[0]);
  final sign = value < 0 ? '-' : '';
  return '$sign\$$grouped,${parts[1]}';
}

String formatDetailStat(double? value) {
  if (value == null) return '—';
  return formatDetailPrice(value);
}

String formatDetailCompact(double? value) {
  if (value == null) return '—';
  final abs = value.abs();
  if (abs >= 1e9) {
    final billions = value / 1e9;
    if (billions.abs() >= 100) {
      final grouped = _groupThousands(billions.abs().round().toString());
      return '${value < 0 ? '-' : ''}\$$grouped Md';
    }
    return '${value < 0 ? '-' : ''}\$${_oneDecimalFr(billions.abs())} Md';
  }
  if (abs >= 1e6) {
    return '${value < 0 ? '-' : ''}\$${_oneDecimalFr(value.abs() / 1e6)} M';
  }
  return formatDetailPrice(value);
}

String formatDetailChange(double change) {
  final sign = change >= 0 ? '+' : '-';
  return '$sign${_oneDecimalFr(change.abs())} % sur 24 h';
}

String _oneDecimalFr(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}


