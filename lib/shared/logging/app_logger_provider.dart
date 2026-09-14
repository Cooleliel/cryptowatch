import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/shared/logging/app_logger.dart';

/// Le logger utilise par les providers de l'application.
///
/// Separe de `app_logger.dart` pour que la couche `data` puisse utiliser le
/// type [AppLog] sans dependre de Riverpod.
///
/// En test, surchargez-le pour capturer les traces :
///
/// ```dart
/// ProviderContainer(overrides: [
///   appLogProvider.overrideWithValue((m, {error, stackTrace}) => traces.add(m)),
/// ]);
/// ```
final Provider<AppLog> appLogProvider = Provider<AppLog>((Ref ref) {
  return defaultAppLog;
});
