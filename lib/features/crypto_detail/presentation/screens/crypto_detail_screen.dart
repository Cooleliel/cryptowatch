import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_provider.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_state.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/widgets/week_line_chart.dart';

/// Fiche crypto. La courbe 7 jours vient de T-10a (plus de points fictifs).
class CryptoDetailScreen extends ConsumerWidget {
  const CryptoDetailScreen({super.key, this.coinId = 'bitcoin'});

  final String coinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartState = ref.watch(priceHistoryProvider(coinId));

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
                const _DetailHeader(),
                const SizedBox(height: 28),
                const Text(
                  r'$112 840,52',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),
                const _ChangePill(),
                const SizedBox(height: 28),
                _ChartSection(
                  state: chartState,
                  onRetry: () =>
                      ref.read(priceHistoryProvider(coinId).notifier).retry(),
                ),
                const SizedBox(height: 28),
                const _StatsGrid(),
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
  const _DetailHeader();

  @override
  Widget build(BuildContext context) {
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
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BitcoinMark(),
                SizedBox(width: 8),
                Text(
                  'Bitcoin',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                _RankBadge(),
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

class _BitcoinMark extends StatelessWidget {
  const _BitcoinMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.bitcoin,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'B',
        style: TextStyle(
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
  const _RankBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.rankBadge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Rang 1',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gainPill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_drop_up, color: AppColors.gain, size: 20),
          Text(
            '+2,4 % sur 24 h',
            style: TextStyle(
              color: AppColors.gain,
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
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: const [
        _StatCard(label: 'Plus haut 24 h', value: r'$114 120'),
        _StatCard(label: 'Plus bas 24 h', value: r'$109 480'),
        _StatCard(label: 'Volume 24 h', value: r'$38,2 Md'),
        _StatCard(label: 'Capitalisation', value: r'$2 230 Md'),
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
