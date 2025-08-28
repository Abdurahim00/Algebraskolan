import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache configuration
class CacheConfig {
  final Duration maxAge;
  final int maxEntries;
  final bool persistent;

  const CacheConfig({
    this.maxAge = const Duration(minutes: 15),
    this.maxEntries = 100,
    this.persistent = false,
  });
}

/// Cache entry with metadata
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final String key;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.key,
  });

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  Map<String, dynamic> toJson(dynamic Function(T) encoder) {
    return {
      'data': encoder(data),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'key': key,
    };
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) decoder,
  ) {
    return CacheEntry(
      data: decoder(json['data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      key: json['key'],
    );
  }
}

/// In-memory and persistent cache manager
class CacheManager {
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  final CacheConfig config;
  Timer? _cleanupTimer;
  SharedPreferences? _prefs;
  
  static const String _cachePrefix = 'cache_';

  CacheManager({this.config = const CacheConfig()}) {
    // Start cleanup timer
    _startCleanupTimer();
    
    // Initialize persistent storage if enabled
    if (config.persistent) {
      _initPersistentStorage();
    }
  }

  Future<void> _initPersistentStorage() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromPersistentStorage();
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpired(),
    );
  }

  /// Get cached data
  Future<T?> get<T>(
    String key, {
    T Function(dynamic)? decoder,
  }) async {
    // Check memory cache first
    final entry = _memoryCache[key];
    if (entry != null && !entry.isExpired(config.maxAge)) {
      return entry.data as T;
    }

    // Check persistent storage if enabled
    if (config.persistent && _prefs != null && decoder != null) {
      final stored = _prefs!.getString('$_cachePrefix$key');
      if (stored != null) {
        try {
          final json = jsonDecode(stored);
          final persistentEntry = CacheEntry<T>.fromJson(json, decoder);
          
          if (!persistentEntry.isExpired(config.maxAge)) {
            // Restore to memory cache
            _memoryCache[key] = persistentEntry;
            return persistentEntry.data;
          } else {
            // Remove expired entry
            await _prefs!.remove('$_cachePrefix$key');
          }
        } catch (e) {
          print('Cache deserialization error: $e');
        }
      }
    }

    return null;
  }

  /// Set cached data
  Future<void> set<T>(
    String key,
    T data, {
    dynamic Function(T)? encoder,
  }) async {
    // Add to memory cache
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      key: key,
    );
    _memoryCache[key] = entry;

    // Enforce max entries limit
    if (_memoryCache.length > config.maxEntries) {
      _evictOldest();
    }

    // Save to persistent storage if enabled
    if (config.persistent && _prefs != null && encoder != null) {
      try {
        final json = jsonEncode(entry.toJson(encoder));
        await _prefs!.setString('$_cachePrefix$key', json);
      } catch (e) {
        print('Cache serialization error: $e');
      }
    }
  }

  /// Invalidate specific cache entry
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    
    if (config.persistent && _prefs != null) {
      await _prefs!.remove('$_cachePrefix$key');
    }
  }

  /// Invalidate cache entries matching pattern
  Future<void> invalidatePattern(String pattern) async {
    final keysToRemove = _memoryCache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      await invalidate(key);
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    
    if (config.persistent && _prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await _prefs!.remove(key);
        }
      }
    }
  }

  /// Get or fetch data with cache
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    T Function(dynamic)? decoder,
    dynamic Function(T)? encoder,
  }) async {
    // Try to get from cache
    final cached = await get<T>(key, decoder: decoder);
    if (cached != null) {
      return cached;
    }

    // Fetch fresh data
    final data = await fetcher();
    
    // Store in cache
    await set(key, data, encoder: encoder);
    
    return data;
  }

  /// Stream with cache support
  Stream<T> streamWithCache<T>(
    String key,
    Stream<T> source, {
    T Function(dynamic)? decoder,
    dynamic Function(T)? encoder,
  }) async* {
    // Emit cached value first if available
    final cached = await get<T>(key, decoder: decoder);
    if (cached != null) {
      yield cached;
    }

    // Then emit fresh values from source
    await for (final value in source) {
      await set(key, value, encoder: encoder);
      yield value;
    }
  }

  void _cleanupExpired() {
    final keysToRemove = <String>[];
    
    _memoryCache.forEach((key, entry) {
      if (entry.isExpired(config.maxAge)) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      invalidate(key);
    }
  }

  void _evictOldest() {
    if (_memoryCache.isEmpty) return;

    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;

    _memoryCache.forEach((key, entry) {
      if (oldestTime == null || entry.timestamp.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = entry.timestamp;
      }
    });

    if (oldestKey != null) {
      invalidate(oldestKey!);
    }
  }

  Future<void> _loadFromPersistentStorage() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final stored = _prefs!.getString(key);
        if (stored != null) {
          try {
            final json = jsonDecode(stored);
            final cacheKey = key.substring(_cachePrefix.length);
            
            // Note: We can't deserialize without knowing the type
            // This would need to be handled by specific cache instances
            print('Found cached entry: $cacheKey');
          } catch (e) {
            print('Failed to load cache entry: $e');
          }
        }
      }
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }
}

/// Repository-specific cache manager
class RepositoryCacheManager extends CacheManager {
  RepositoryCacheManager({
    Duration maxAge = const Duration(minutes: 5),
    bool persistent = true,
  }) : super(
          config: CacheConfig(
            maxAge: maxAge,
            maxEntries: 50,
            persistent: persistent,
          ),
        );

  /// Cache key builders
  String studentKey(String studentId) => 'student_$studentId';
  String studentsKey(int? classNumber) => 'students_${classNumber ?? 'all'}';
  String transactionsKey(String studentId) => 'transactions_$studentId';
  String userKey(String userId) => 'user_$userId';

  /// Invalidate all student-related cache
  Future<void> invalidateStudent(String studentId) async {
    await invalidatePattern('student_$studentId');
    await invalidatePattern('students_'); // Invalidate all student lists
  }

  /// Invalidate all transaction-related cache  
  Future<void> invalidateTransactions(String studentId) async {
    await invalidatePattern('transactions_$studentId');
  }
}