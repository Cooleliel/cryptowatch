import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_provider.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_state.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/widgets/week_line_chart.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';

/// Fiche crypto. La courbe 7 jours vient de T-10a.
/// Nom, prix et stats viennent du [Crypto] passé par la liste (T-04b).
/// Sans [crypto], le mockup Bitcoin est conservé (tests T-04 / T-10b).
class CryptoDetailScreen extends ConsumerWidget {
  const CryptoDetailScreen({super.key, this.coinId = 'bitcoin', this.crypto});

  final String coinId;
  final Crypto? crypto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartState = ref.watch(priceHistoryProvider(coinId));
    final selected = crypto;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailHeader(crypto: selected),
                const SizedBox(height: 28),
                Text(
                  selected == null
                      ? r'$112 840,52'
                      : formatDetailPrice(selected.currentPrice),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),
                _ChangePill(
                  change: selected?.priceChangePercentage24h,
                  useMockup: selected == null,
                ),
                const SizedBox(height: 28),
                _ChartSection(
                  state: chartState,
                  onRetry: () =>
                      ref.read(priceHistoryProvider(coinId).notifier).retry(),
                ),
                const SizedBox(height: 28),
                _StatsGrid(crypto: selected),
              ],
            ),
          ),
        ),
      ),
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
          child: Center(child: CircularProgressIndicator()),
        ),
      PriceHistoryError(:final message) => SizedBox(
          height: 196,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
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
      PriceHistoryLoaded(:final prices) => WeekLineChart(values: prices),
    };
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({this.crypto});

  final Crypto? crypto;

  @override
  Widget build(BuildContext context) {
    final selected = crypto;
    final name = selected?.name ?? 'Bitcoin';
    final letter = selected == null
        ? 'B'
        : (selected.symbol.isNotEmpty
            ? selected.symbol[0].toUpperCase()
            : '?');
    final markColor = selected == null
        ? AppColors.bitcoin
        : _markColorFor(selected.symbol);
    final rank = selected == null
        ? 1
        : selected.marketCapRank;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              final navigator = Navigator.maybeOf(context);
              if (navigator != null && navigator.canPop()) {
                navigator.pop();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.textPrimary,
              size: 32,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CoinMark(letter: letter, color: markColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (rank != null) ...[
                  const SizedBox(width: 8),
                  _RankBadge(label: 'Rang $rank'),
                ],
              ],
            ),
          ),
          const Icon(Icons.star, color: AppColors.bitcoin, size: 22),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CoinMark extends StatelessWidget {
  const _CoinMark({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({this.change, this.useMockup = false});

  final double? change;
  final bool useMockup;

  static const _loss = Color(0xFFE85D75);
  static const _lossPill = Color(0xFF2A1620);

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.gainPill : _lossPill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isPositive ? AppColors.gain : _loss,
            size: 20,
          ),
          Text(
            label,
            style: TextStyle(
              color: isPositive ? AppColors.gain : _loss,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
      childAspectRatio: 1.55,
      children: [
        _StatCard(label: 'Plus haut 24 h', value: high),
        _StatCard(label: 'Plus bas 24 h', value: low),
        _StatCard(label: 'Volume 24 h', value: volume),
        _StatCard(label: 'Capitalisation', value: cap),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
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
