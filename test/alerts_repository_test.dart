import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:cryptowatch/features/alerts/data/alerts_repository.dart';
import 'package:cryptowatch/features/alerts/domain/price_alert.dart';

/// Redirige path_provider vers un dossier temporaire réel et isolé, créé et
/// détruit pour chaque test — pas besoin de mocker le contenu du fichier.
class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.tempDir);

  final Directory tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  late Directory tempDir;
  late AlertsRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('alerts_repo_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
    repository = AlertsRepository();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadAlerts renvoie une liste vide si le fichier n\'existe pas', () async {
    final alerts = await repository.loadAlerts();
    expect(alerts, isEmpty);
  });

  test('saveAlerts puis loadAlerts redonne les mêmes alertes', () async {
    final alerts = [
      const PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
      ),
      const PriceAlert(
        id: '2',
        cryptoId: 'ethereum',
        cryptoSymbol: 'eth',
        threshold: 3000,
        condition: AlertCondition.below,
        active: false,
      ),
    ];

    await repository.saveAlerts(alerts);
    final loaded = await repository.loadAlerts();

    expect(loaded.length, 2);
    expect(loaded[0].id, '1');
    expect(loaded[0].threshold, 50000);
    expect(loaded[1].active, false);
  });

  test('saveAlerts avec une liste vide écrit un fichier JSON vide exploitable', () async {
    await repository.saveAlerts([]);
    final loaded = await repository.loadAlerts();
    expect(loaded, isEmpty);
  });

  test('loadAlerts renvoie une liste vide si le fichier contient du JSON invalide', () async {
    final file = File('${tempDir.path}/price_alerts.json');
    await file.writeAsString('{ceci n\'est pas du json valide');

    final alerts = await repository.loadAlerts();
    expect(alerts, isEmpty);
  });

  test('loadAlerts ignore un fichier JSON qui n\'est pas une liste', () async {
    final file = File('${tempDir.path}/price_alerts.json');
    await file.writeAsString(jsonEncode({'not': 'a list'}));

    final alerts = await repository.loadAlerts();
    expect(alerts, isEmpty);
  });

  test('saveAlerts écrase le contenu précédent (pas d\'append)', () async {
    await repository.saveAlerts([
      const PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
      ),
    ]);

    await repository.saveAlerts([
      const PriceAlert(
        id: '2',
        cryptoId: 'ethereum',
        cryptoSymbol: 'eth',
        threshold: 3000,
        condition: AlertCondition.below,
      ),
    ]);

    final loaded = await repository.loadAlerts();
    expect(loaded.length, 1);
    expect(loaded.first.id, '2');
  });
}