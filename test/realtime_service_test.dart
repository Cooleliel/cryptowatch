import 'dart:async';
import 'dart:convert';

import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:cryptowatch/features/market/data/realtime_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Faux WebSocket : le test pousse des messages dans [incoming], le service
/// les reçoit comme s'ils venaient de Binance. Même principe que le faux
/// client HTTP des repositories : on contrôle la source au lieu de la subir.
class _FakeWebSocketChannel implements WebSocketChannel {
  final StreamController<dynamic> incoming =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> outgoing =
      StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(outgoing.sink);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Enveloppe le sink pour satisfaire l'interface WebSocketSink.
class _FakeWebSocketSink implements WebSocketSink {
  _FakeWebSocketSink(this._inner);

  final StreamSink<dynamic> _inner;

  @override
  Future<void> close([int? closeCode, String? closeReason]) => _inner.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BinanceTicker.tryParse', () {
    test('normalise le symbole BTCUSDT en btc', () {
      final BinanceTicker? ticker = BinanceTicker.tryParse(<String, dynamic>{
        's': 'BTCUSDT',
        'c': '45100.5',
      });
      expect(ticker, isNotNull);
      expect(ticker!.symbol, 'btc');
      expect(ticker.raw['c'], '45100.5');
    });

    test('retourne null pour un message sans symbole ou mal formé', () {
      expect(BinanceTicker.tryParse(<String, dynamic>{'e': 'ping'}), isNull);
      expect(BinanceTicker.tryParse('pas-un-objet'), isNull);
      expect(BinanceTicker.tryParse(null), isNull);
      expect(BinanceTicker.tryParse(<String, dynamic>{'s': ''}), isNull);
    });
  });

  group('RealtimeService', () {
    test('émet un ticker par entrée du tableau miniTicker', () async {
      final _FakeWebSocketChannel channel = _FakeWebSocketChannel();
      final RealtimeService service = RealtimeService(
        connect: (Uri _) => channel,
      )..start();

      final Future<List<BinanceTicker>> receiving = service.tickers
          .take(2)
          .toList();

      channel.incoming.add(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'s': 'BTCUSDT', 'c': '45100'},
          <String, dynamic>{'s': 'ETHUSDT', 'c': '3050'},
        ]),
      );

      final List<BinanceTicker> received = await receiving;
      expect(received.map((BinanceTicker t) => t.symbol), <String>[
        'btc',
        'eth',
      ]);
      service.dispose();
    });

    test('ignore les messages illisibles sans fermer le flux', () async {
      final _FakeWebSocketChannel channel = _FakeWebSocketChannel();
      final RealtimeService service = RealtimeService(
        connect: (Uri _) => channel,
      )..start();

      final Future<BinanceTicker> receiving = service.tickers.first;

      channel.incoming.add('pas du json');
      channel.incoming.add(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'s': 'SOLUSDT', 'c': '241'},
        ]),
      );

      final BinanceTicker ticker = await receiving;
      expect(ticker.symbol, 'sol');
      service.dispose();
    });

    test('se reconnecte quand le flux se ferme', () {
      fakeAsync((FakeAsync async) {
        int connections = 0;
        final List<_FakeWebSocketChannel> channels = <_FakeWebSocketChannel>[];
        final RealtimeService service = RealtimeService(
          connect: (Uri _) {
            connections++;
            final _FakeWebSocketChannel channel = _FakeWebSocketChannel();
            channels.add(channel);
            return channel;
          },
        )..start();

        expect(connections, 1);
        channels.first.incoming.close(); // Binance raccroche
        async.elapse(const Duration(seconds: 2));
        expect(connections, 2); // le service est revenu tout seul

        service.dispose();
      });
    });
  });
}
