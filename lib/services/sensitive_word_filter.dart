import 'package:supabase_flutter/supabase_flutter.dart';

/// 敏感词过滤服务
/// 用于在发布内容前检测敏感词，并自动替换为屏蔽符号
class SensitiveWordFilter {
  static final SensitiveWordFilter _instance = SensitiveWordFilter._internal();
  factory SensitiveWordFilter() => _instance;
  SensitiveWordFilter._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// 内存中的敏感词缓存（从数据库加载）
  Set<String>? _wordCache;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  /// 检测文本是否包含敏感词
  /// 返回 (是否安全, 过滤后的文本)
  Future<(bool, String)> checkAndFilter(String text) async {
    try {
      final words = await _getSensitiveWords();
      if (words.isEmpty) return (true, text);

      String filteredText = text;
      bool hasSensitive = false;

      for (final word in words) {
        if (text.contains(word)) {
          hasSensitive = true;
          filteredText = filteredText.replaceAll(word, '*' * word.length);
        }
      }

      return (!hasSensitive, filteredText);
    } catch (e) {
      // 过滤服务出错时，默认通过（不阻塞用户）
      return (true, text);
    }
  }

  /// 仅检测是否包含敏感词，不返回过滤后的文本
  Future<bool> containsSensitive(String text) async {
    try {
      final words = await _getSensitiveWords();
      if (words.isEmpty) return false;
      return words.any((word) => text.contains(word));
    } catch (e) {
      return false;
    }
  }

  /// 获取敏感词列表（带缓存）
  Future<Set<String>> _getSensitiveWords() async {
    // 如果缓存有效，直接返回
    if (_wordCache != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _wordCache!;
    }

    try {
      final resp = await _client
          .from('sensitive_words')
          .select('word')
          .eq('is_active', true);

      final words = (resp as List)
          .map((item) => item['word'] as String)
          .toSet();

      _wordCache = words;
      _lastFetchTime = DateTime.now();

      return words;
    } catch (e) {
      // 如果数据库查询失败，返回空集合（不阻塞功能）
      return _wordCache ?? {};
    }
  }

  /// 清除缓存，强制重新加载
  void clearCache() {
    _wordCache = null;
    _lastFetchTime = null;
  }
}
