import 'dart:async';
import 'dart:convert';

import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

//** Un service pour gérer les données en temps réel */
class RealtimeService {
  //**  Crée un nouveau RealtimeService. */
  RealtimeService({WebSocketChannel Function(Uri)? connect})
    : _connect = connect ?? WebSocketChannel.connect;

  //** Fonction pour établir une connexion WebSocket. */
  final WebSocketChannel Function(Uri) _connect;

  //** URI du flux en temps réel */
  static final Uri _streamUri = Uri.parse(
    'wss://stream.binance.com:9443/ws/!miniTicker@arr',
  );

  //** Contrôleur pour gérer les flux de données */
  final StreamController<BinanceTicker> _controller =
      StreamController<BinanceTicker>.broadcast();

  WebSocketChannel?
  _channel; //** Canal WebSocket pour la connexion en temps réel */
  StreamSubscription<dynamic>?
  _subscription; //** Abonnement pour écouter les messages du canal WebSocket */
  Timer?
  _reconnectTimer; //** Minuterie pour gérer les tentatives de reconnexion */
  int _retryCount =
      0; //** Compteur pour suivre le nombre de tentatives de reconnexion */
  bool _disposed = false; //** Indique si le service a été disposé */

  //** Flux de données des tickers Binance */
  Stream<BinanceTicker> get tickers => _controller.stream;

  //** Démarre le service en établissant une connexion WebSocket et en écoutant les messages entrants. */
  void start() {
    if (_disposed || _channel != null) return;
    try {
      _channel = _connect(_streamUri); //** Établit la connexion WebSocket */
    } catch (_) {
      _scheduleReconnect(); //** Planifie une tentative de reconnexion en cas d'échec */
      return;
    }

    //** Écoute les messages du canal WebSocket */
    _subscription = _channel!.stream.listen(
      _onMessage, //** Appelle la fonction _onMessage pour traiter les messages entrants */
      onError: (Object _) =>
          _onConnectionLost(), //** Appelle la fonction _onConnectionLost en cas d'erreur */
      onDone:
          _onConnectionLost, //** Appelle la fonction _onConnectionLost lorsque la connexion est fermée */
      cancelOnError:
          false, //** Indique que l'abonnement ne doit pas être annulé en cas d'erreur */
    );
  }

  //** Fonction pour traiter les messages entrants du canal WebSocket. */
  void _onMessage(dynamic message) {
    _retryCount = 0;
    if (message is! String) return;

    Object? decoded;
    try {
      decoded = jsonDecode(
        message,
      ); //** Décode le message JSON en un objet Dart */
    } on FormatException {
      return;
    }

    final List<Object?> items = decoded is List
        ? decoded
        : <Object?>[
            decoded,
          ]; //** Assure que les données sont traitées comme une liste, même si un seul élément est reçu */

    for (final Object? item in items) {
      //** Tente de parser le ticker Binance */
      final BinanceTicker? ticker = BinanceTicker.tryParse(
        item is Map<String, dynamic> ? item : null,
      );

      if (ticker != null) {
        _controller.add(
          ticker,
        ); //** Ajoute le ticker au flux de données pour que les abonnés puissent le recevoir */
      }
    }
  }

  //** Fonction appelée lorsque la connexion est perdue. */
  void _onConnectionLost() {
    _tearDownChannel();
    _scheduleReconnect();
  }

  //** Nettoie le canal WebSocket. */
  void _tearDownChannel() {
    _subscription
        ?.cancel(); //** Annule l'abonnement pour arrêter d'écouter les messages du canal WebSocket */
    _subscription = null; //** Réinitialise l'abonnement */
    _channel?.sink.close(); //** Ferme le canal WebSocket */
    _channel = null; //** Réinitialise le canal WebSocket */
  }

  //** Planifie une tentative de reconnexion. */
  void _scheduleReconnect() {
    if (_disposed) return;

    final int seconds =
        1 <<
        _retryCount; //** Calcule le délai avant la prochaine tentative de reconnexion en utilisant une exponentiation binaire */

    final Duration delay = Duration(
      seconds: seconds > 30 ? 30 : seconds,
    ); //** Limite le délai à 30 secondes pour éviter des délais trop longs */
    _retryCount = _retryCount > 5
        ? _retryCount
        : _retryCount +
              1; //** Incrémente le compteur de tentatives de reconnexion, mais ne le laisse pas dépasser 5 pour éviter des délais trop longs */
    _reconnectTimer
        ?.cancel(); //** Annule toute tentative de reconnexion précédente pour éviter des conflits */
    _reconnectTimer = Timer(delay, () {
      //** Planifie une nouvelle tentative de reconnexion après le délai calculé */
      _channel = null;
      start(); //** Redémarre le service pour tenter de rétablir la connexion WebSocket */
    });
  }

  //** Dispose le service en nettoyant les ressources et en fermant le flux de données. */
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _tearDownChannel();
    _controller.close();
  }
}
