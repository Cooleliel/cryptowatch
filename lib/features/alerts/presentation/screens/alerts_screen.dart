import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:cryptowatch/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alertes de prix')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-alert-button'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openCreateDialog(context, ref),
        child: const Icon(Icons.add_alert),
      ),
      body: alerts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Aucune alerte configurée',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Touche + pour être prévenu quand un prix franchit '
                        'ton seuil.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: alerts.length,
              itemBuilder: (context, index) => _AlertTile(alert: alerts[index]),
            ),
    );
  }

  void _openCreateDialog(BuildContext context, WidgetRef ref) {
    final cryptos = ref.read(marketProvider).value ?? const <Crypto>[];
    if (cryptos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le marché n\'est pas encore chargé.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _CreateAlertDialog(cryptos: cryptos),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.alert});

  final PriceAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAbove = alert.condition == AlertCondition.above;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          isAbove ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: isAbove ? AppColors.gain : AppColors.loss,
        ),
        title: Text(
          '${alert.cryptoName} (${alert.cryptoSymbol.toUpperCase()})',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${isAbove ? 'Au-dessus de' : 'En dessous de'} '
          '${alert.threshold.toStringAsFixed(2)} \$',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.active,
              activeThumbColor: AppColors.primary,
              onChanged: (_) =>
                  ref.read(alertsProvider.notifier).toggleActive(alert.id),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  ref.read(alertsProvider.notifier).removeAlert(alert.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAlertDialog extends ConsumerStatefulWidget {
  const _CreateAlertDialog({required this.cryptos});

  final List<Crypto> cryptos;

  @override
  ConsumerState<_CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends ConsumerState<_CreateAlertDialog> {
  Crypto? _selected;
  AlertCondition _condition = AlertCondition.above;
  final _thresholdController = TextEditingController();

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final t = double.tryParse(_thresholdController.text.replaceAll(',', '.'));
    return _selected != null && t != null && t > 0;
  }

  void _submit() {
    final crypto = _selected!;
    final threshold = double.parse(
      _thresholdController.text.replaceAll(',', '.'),
    );
    ref
        .read(alertsProvider.notifier)
        .addAlert(
          PriceAlert(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            cryptoId: crypto.id,
            cryptoSymbol: crypto.symbol,
            cryptoName: crypto.name,
            threshold: threshold,
            condition: _condition,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Nouvelle alerte',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Crypto>(
            key: const Key('alert-crypto-dropdown'),
            decoration: const InputDecoration(labelText: 'Crypto'),
            items: widget.cryptos
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      '${c.name} — ${c.currentPrice.toStringAsFixed(2)} \$',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (c) => setState(() => _selected = c),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AlertCondition>(
            segments: const [
              ButtonSegment(
                value: AlertCondition.above,
                label: Text('Au-dessus'),
                icon: Icon(Icons.trending_up),
              ),
              ButtonSegment(
                value: AlertCondition.below,
                label: Text('En dessous'),
                icon: Icon(Icons.trending_down),
              ),
            ],
            selected: {_condition},
            onSelectionChanged: (s) => setState(() => _condition = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('alert-threshold-field'),
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Seuil',
              prefixText: '\$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('alert-submit-button'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
