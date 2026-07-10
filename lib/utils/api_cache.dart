import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight API cache with stale-while-revalidate (SWR) pattern.
///
/// Two layers:
///   1. Memory – LRU map, capped at 100 entries, instant reads.
///   2. Disk   – SharedPreferences (JSON), survives app restarts.
///
/// Mirrors the web app's `apiCache.ts` strategy.
class ApiCache {
  static final ApiCache instance = ApiCache._();
  ApiCache._();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------
  static const int _maxMemoryEntries = 100;
  static const String _diskPrefix = 'api_cache:';

  // ---------------------------------------------------------------------------
  // Memory cache (LRU – re-insert on read to maintain access order)
  // ---------------------------------------------------------------------------
  final Map<String, _CacheEntry> _memory = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Read from cache. Returns `null` if missing or expired.
  Future<T?> get<T>(String key) async {
    // 1) Memory hit
    final mem = _memory[key];
    if (mem != null) {
      if (!mem.isExpired) {
        _touchLru(key, mem);
        return mem.data as T?;
      }
      _memory.remove(key);
    }

    // 2) Disk hit
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_diskPrefix$key');
      if (raw != null) {
        final entry = _CacheEntry.fromJson(raw);
        if (entry != null && !entry.isExpired) {
          _touchLru(key, entry);
          return entry.data as T?;
        }
        await prefs.remove('$_diskPrefix$key');
      }
    } catch (e) {
      debugPrint('[ApiCache] disk read error ($key): $e');
    }
    return null;
  }

  /// Write to both memory and disk.
  Future<void> set<T>(String key, T data,
      {Duration ttl = const Duration(minutes: 5)}) async {
    final entry = _CacheEntry(
      key: key,
      data: data,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(ttl),
    );
    _touchLru(key, entry);

    // Persist to disk (fire-and-forget)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_diskPrefix$key', entry.toJson());
    } catch (e) {
      debugPrint('[ApiCache] disk write error ($key): $e');
    }
  }

  /// Invalidate a single key.
  Future<void> invalidate(String key) async {
    _memory.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_diskPrefix$key');
    } catch (_) {}
  }

  /// Invalidate all keys matching [prefix].
  Future<void> invalidatePrefix(String prefix) async {
    final keysToRemove =
        _memory.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in keysToRemove) {
      _memory.remove(k);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys()) {
        if (k.startsWith('$_diskPrefix$prefix')) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}
  }

  /// Clear every cached entry (memory + disk).
  Future<void> clear() async {
    _memory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith(_diskPrefix)).toList()) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  /// Stale-while-revalidate.
  ///
  /// * If a **fresh** entry exists (age < [staleTime]), return it immediately
  ///   with no background refresh.
  /// * If a **stale** (but not expired) entry exists, return it immediately and
  ///   kick off a background [fetcher]; [onRefresh] is called with new data.
  /// * If nothing is cached, await [fetcher] directly.
  Future<T?> staleWhileRevalidate<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration staleTime = const Duration(minutes: 1),
    Duration ttl = const Duration(minutes: 5),
    void Function(T data)? onRefresh,
  }) async {
    // Check memory first
    final mem = _memory[key];
    if (mem != null && !mem.isExpired) {
      final age = DateTime.now().difference(mem.createdAt);
      if (age < staleTime) {
        _touchLru(key, mem);
        return mem.data as T?;
      }
      // Stale-but-valid – return now, refresh in background
      final cached = mem.data as T?;
      _backgroundRefresh<T>(key, fetcher, ttl, onRefresh);
      return cached;
    }

    // Check disk
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_diskPrefix$key');
      if (raw != null) {
        final entry = _CacheEntry.fromJson(raw);
        if (entry != null && !entry.isExpired) {
          _touchLru(key, entry);
          final age = DateTime.now().difference(entry.createdAt);
          if (age < staleTime) {
            return entry.data as T?;
          }
          final cached = entry.data as T?;
          _backgroundRefresh<T>(key, fetcher, ttl, onRefresh);
          return cached;
        }
      }
    } catch (e) {
      debugPrint('[ApiCache] SWR disk read error ($key): $e');
    }

    // Cache miss – must wait for the network
    try {
      final data = await fetcher();
      await set<T>(key, data, ttl: ttl);
      return data;
    } catch (e) {
      debugPrint('[ApiCache] SWR fetcher error ($key): $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Insert / re-insert at the end of the LinkedHashMap (LRU order) and evict
  /// the oldest entry when over capacity.
  void _touchLru(String key, _CacheEntry entry) {
    _memory.remove(key);
    _memory[key] = entry;
    while (_memory.length > _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  void _backgroundRefresh<T>(
    String key,
    Future<T> Function() fetcher,
    Duration ttl,
    void Function(T data)? onRefresh,
  ) async {
    try {
      final data = await fetcher();
      await set<T>(key, data, ttl: ttl);
      onRefresh?.call(data);
    } catch (e) {
      debugPrint('[ApiCache] background refresh error ($key): $e');
    }
  }
}

// =============================================================================
// Internal cache entry
// =============================================================================
class _CacheEntry {
  final String key;
  final dynamic data;
  final DateTime createdAt;
  final DateTime expiresAt;

  _CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String toJson() => jsonEncode({
        'key': key,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });

  static _CacheEntry? fromJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _CacheEntry(
        key: m['key'] as String,
        data: m['data'],
        createdAt: DateTime.parse(m['createdAt'] as String),
        expiresAt: DateTime.parse(m['expiresAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
