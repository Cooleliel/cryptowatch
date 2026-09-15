import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:cryptowatch/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlerts = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertes de prix')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateDialog(context, ref),
        child: const Icon(Icons.add_alert),
      ),
      body: asyncAlerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Impossible de charger les alertes.'),
        ),
        data: (alerts) => alerts.isEmpty
            ? const Center(child: Text('Aucune alerte configurée.'))
            : ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _AlertTile(alert: alert);
                },
              ),
      ),
    );
  }

  void _openCreateDialog(BuildContext context, WidgetRef ref) {
    final asyncCryptos = ref.read(marketProvider);
    final cryptos = asyncCryptos.value ?? [];
    if (cryptos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marché pas encore chargé.')),
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
    final conditionLabel = alert.condition == AlertCondition.above
        ? 'au-dessus de'
        : 'en dessous de';

    return ListTile(
      leading: Icon(
        alert.condition == AlertCondition.above
            ? Icons.trending_up
            : Icons.trending_down,
      ),
      title: Text(alert.cryptoSymbol.toUpperCase()),
      subtitle: Text(
        '$conditionLabel ${alert.threshold.toStringAsFixed(2)} \$',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: alert.active,
            onChanged: (_) =>
                ref.read(alertsProvider.notifier).toggleActive(alert.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                ref.read(alertsProvider.notifier).removeAlert(alert.id),
          ),
        ],
      ),
    );
  }
}

class _CreateAlertDialog extends ConsumerStatefulWidget {
  const _CreateAlertDialog({required this.cryptos});

  final List<Crypto> cryptos;

  @override
  ConsumerState<_CreateAlertDialog> createState() =>
      _CreateAlertDialogState();
}

class _CreateAlertDialogState extends ConsumerState<_CreateAlertDialog> {
  Crypto? _selectedCrypto;
  AlertCondition _condition = AlertCondition.above;
  final _thresholdController = TextEditingController();

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle alerte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Crypto>(
            initialValue: _selectedCrypto,
            decoration: const InputDecoration(labelText: 'Crypto'),
            items: widget.cryptos
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.name} (${c.symbol.toUpperCase()})'),
                  ),
                )
                .toList(),
            onChanged: (c) => setState(() => _selectedCrypto = c),
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
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Seuil (\$)',
              prefixText: '\$ ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Créer'),
        ),
      ],
    );
  }

  bool get _canSubmit {
    final threshold = double.tryParse(_thresholdController.text);
    return _selectedCrypto != null && threshold != null && threshold > 0;
  }

  void _submit() {
    final crypto = _selectedCrypto!;
    final threshold = double.parse(_thresholdController.text);

    ref.read(alertsProvider.notifier).addAlert(
          PriceAlert(
            id: const Uuid().v4(),
            cryptoId: crypto.id,
            cryptoSymbol: crypto.symbol,
            threshold: threshold,
            condition: _condition,
          ),
        );

    Navigator.of(context).pop();
  }
}