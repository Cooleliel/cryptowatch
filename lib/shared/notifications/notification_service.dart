import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';

/// Un événement d'alerte déclenchée, pour que l'UI (SnackBar, badge...)
/// puisse réagir sans dépendre directement d'AlertsNotifier.
class AlertTriggeredEvent {
  const AlertTriggeredEvent({
    required this.cryptoName,
    required this.price,
    required this.condition,
    required this.threshold,
  });

  final String cryptoName;
  final double price;
  final AlertCondition condition;
  final double threshold;

  String get message {
    final directionWord =
        condition == AlertCondition.above ? 'dépassé' : 'passé sous';
    final priceText = price.toStringAsFixed(2);
    final thresholdText = threshold.toStringAsFixed(2);
    return '$cryptoName a $directionWord $thresholdText \$ '
        '(actuellement $priceText \$)';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final alertEventsProvider = StreamProvider<AlertTriggeredEvent>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.events;
});

class NotificationService {
  NotificationService() {
    _init();
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<AlertTriggeredEvent> _eventsController =
      StreamController<AlertTriggeredEvent>.broadcast();
  bool _systemNotificationsReady = false;

  Stream<AlertTriggeredEvent> get events => _eventsController.stream;

  Future<void> _init() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings: initSettings);

      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          _plugin.resolvePlatformSpecificImplementation
              <AndroidFlutterLocalNotificationsPlugin>();
      final bool? androidGranted =
          await androidImpl?.requestNotificationsPermission();

      final IOSFlutterLocalNotificationsPlugin? iosImpl =
          _plugin.resolvePlatformSpecificImplementation
              <IOSFlutterLocalNotificationsPlugin>();
      final bool? iosGranted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      final bool androidOk = androidGranted ?? true;
      final bool iosOk = iosGranted ?? true;
      _systemNotificationsReady = androidOk && iosOk;
    } catch (_) {
      // Permission refusée ou plateforme non supportée : on continue avec
      // l'in-app uniquement, jamais de crash pour ça.
      _systemNotificationsReady = false;
    }
  }

  Future<void> showPriceAlert({
    required String cryptoName,
    required double price,
    required AlertCondition condition,
    required double threshold,
  }) async {
    final AlertTriggeredEvent event = AlertTriggeredEvent(
      cryptoName: cryptoName,
      price: price,
      condition: condition,
      threshold: threshold,
    );

    _eventsController.add(event);

    if (_systemNotificationsReady) {
      try {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'price_alerts',
          'Alertes de prix',
          importance: Importance.high,
          priority: Priority.high,
        );
        const DarwinNotificationDetails iosDetails =
            DarwinNotificationDetails();
        const NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _plugin.show(
          id: event.hashCode,
          title: 'CryptoWatch — Alerte de prix',
          body: event.message,
          notificationDetails: details,
        );
      } catch (_) {
        // Best-effort : une notif système ratée ne doit jamais faire
        // échouer l'alerte in-app déjà émise ci-dessus.
      }
    }
  }

  void dispose() {
    _eventsController.close();
  }
}