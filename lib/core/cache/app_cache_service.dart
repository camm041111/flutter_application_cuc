import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return AppCacheService();
});

class CacheTtl {
  static const catalogs = Duration(hours: 24);
  static const profile = Duration(minutes: 10);
  static const club = Duration(minutes: 10);
  static const events = Duration(minutes: 3);
  static const repository = Duration(minutes: 3);
}

class CachedValue<T> {
  const CachedValue({
    required this.value,
    required this.updatedAt,
  });

  final T value;
  final DateTime updatedAt;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(updatedAt) < ttl;
  }
}

class AppCacheService {
  final Map<String, CachedValue<Object?>> _memory = {};
  final Map<String, Future<Object?>> _inFlight = {};
  SharedPreferences? _prefs;

  Future<CachedValue<T>?> read<T>(
    String key, {
    required T Function(Object? json) fromJson,
    bool persistent = true,
  }) async {
    final memoryValue = _memory[key];
    if (memoryValue != null) {
      return CachedValue<T>(
        value: memoryValue.value as T,
        updatedAt: memoryValue.updatedAt,
      );
    }

    if (!persistent) return null;

    final prefs = await _preferences();
    final raw = prefs.getString(_storageKey(key));
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final updatedAt = DateTime.parse(decoded['updatedAt'].toString());
      final value = fromJson(decoded['value']);
      final cached = CachedValue<Object?>(value: value, updatedAt: updatedAt);
      _memory[key] = cached;
      return CachedValue<T>(value: value, updatedAt: updatedAt);
    } catch (error, stackTrace) {
      debugPrint('No se pudo leer la cache "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
      await prefs.remove(_storageKey(key));
      return null;
    }
  }

  Future<void> write<T>(
    String key,
    T value, {
    required Object? Function(T value) toJson,
    bool persistent = true,
  }) async {
    final updatedAt = DateTime.now();
    _memory[key] = CachedValue<Object?>(value: value, updatedAt: updatedAt);

    if (!persistent) return;

    final prefs = await _preferences();
    await prefs.setString(
      _storageKey(key),
      jsonEncode({
        'updatedAt': updatedAt.toIso8601String(),
        'value': toJson(value),
      }),
    );
  }

  Future<T> staleWhileRevalidate<T>({
    required Ref ref,
    required String key,
    required Duration ttl,
    required Future<T> Function() fetch,
    required T Function(Object? json) fromJson,
    required Object? Function(T value) toJson,
    bool persistent = true,
  }) async {
    final cached = await read<T>(
      key,
      fromJson: fromJson,
      persistent: persistent,
    );

    if (cached != null) {
      if (!cached.isFresh(ttl)) {
        unawaited(_refresh(
          ref: ref,
          key: key,
          fetch: fetch,
          toJson: toJson,
          persistent: persistent,
          invalidateWhenDone: true,
        ).catchError((error, stackTrace) {
          debugPrint('No se pudo refrescar la cache "$key": $error');
          debugPrintStack(stackTrace: stackTrace);
          return cached.value;
        }));
      }
      return cached.value;
    }

    return _refresh(
      ref: ref,
      key: key,
      fetch: fetch,
      toJson: toJson,
      persistent: persistent,
      invalidateWhenDone: false,
    );
  }

  Future<void> invalidate(String key) async {
    _memory.remove(key);
    final prefs = await _preferences();
    await prefs.remove(_storageKey(key));
  }

  Future<void> invalidatePrefix(String prefix) async {
    _memory.removeWhere((key, _) => key.startsWith(prefix));
    final prefs = await _preferences();
    final storagePrefix = _storageKey(prefix);
    final keys = prefs.getKeys().where((key) => key.startsWith(storagePrefix));
    await Future.wait(keys.map(prefs.remove));
  }

  Future<void> clearUserScoped() async {
    await invalidatePrefix('profile:');
    await invalidatePrefix('events:');
  }

  Future<T> _refresh<T>({
    required Ref ref,
    required String key,
    required Future<T> Function() fetch,
    required Object? Function(T value) toJson,
    required bool persistent,
    required bool invalidateWhenDone,
  }) async {
    final existing = _inFlight[key];
    if (existing != null) return existing as Future<T>;

    final future = (() async {
      final fresh = await fetch();
      await write<T>(
        key,
        fresh,
        toJson: toJson,
        persistent: persistent,
      );
      if (invalidateWhenDone) {
        try {
          ref.invalidateSelf();
        } catch (_) {
          // El provider puede haberse descartado mientras el refresh seguía vivo.
        }
      }
      return fresh;
    })();

    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _storageKey(String key) => 'cuc_cache::$key';
}
