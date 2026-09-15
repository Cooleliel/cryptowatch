import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';

class AlertsRepository {
  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/price_alerts.json');
  }

  Future<List<PriceAlert>> loadAlerts() async {
    final file = await _getFile();
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PriceAlert.fromJson)
          .toList();
    } catch (_) {
      // Fichier corrompu ou absent de contenu exploitable : on repart propre
      // plutôt que de planter l'app au démarrage.
      return [];
    }
  }

  Future<void> saveAlerts(List<PriceAlert> alerts) async {
    final file = await _getFile();
    final json = jsonEncode(alerts.map((a) => a.toJson()).toList());
    await file.writeAsString(json);
  }
}