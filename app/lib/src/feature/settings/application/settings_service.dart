import 'dart:async';

import 'package:common_utils/common_utils.dart';

import 'package:shchitovik/src/feature/settings/domain/model/settings.dart';
import 'package:shchitovik/src/feature/settings/domain/repositories/settings_repository.dart';

abstract interface class SettingsService() {
  /// Emits settings whenever they change.
  Stream<Settings> get stream;

  /// Current in-memory settings.
  Settings get current;

  /// Update settings transactionally and persist them.
  Future<void> update(Settings Function(Settings current) transform);
}

final class SettingsServiceImpl._(final SettingsRepository _repository, var Settings _current)
    implements SettingsService {
  /// Create a new [SettingsServiceImpl] with the given [repository].
  static Future<SettingsServiceImpl> create({required SettingsRepository repository}) async {
    final Settings current = await repository.read();
    return SettingsServiceImpl._(repository, current);
  }

  final _controller = StreamController<Settings>.broadcast();
  final _mutex = MutexLock();
  @override
  Stream<Settings> get stream => _controller.stream;

  @override
  Settings get current => _current;

  @override
  Future<void> update(Settings Function(Settings) transform) => _mutex.runLocked(() async {
    final Settings updated = transform(current);
    await _repository.save(updated);
    _current = updated;
    _controller.add(updated);
  });
}
