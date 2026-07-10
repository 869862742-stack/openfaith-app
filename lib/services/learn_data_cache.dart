import 'package:supabase_flutter/supabase_flutter.dart';

/// 学习数据预加载缓存 - 轻量级内存缓存
/// 网页版 preloadLearnData() 的 Flutter 对应实现
class LearnDataCache {
  static final LearnDataCache _instance = LearnDataCache._internal();
  factory LearnDataCache() => _instance;
  LearnDataCache._internal();

  bool _loaded = false;
  bool _loading = false;
  
  List<Map<String, dynamic>> _religions = [];
  List<Map<String, dynamic>> _bookGroups = [];
  List<Map<String, dynamic>> _books = [];
  Map<String, int> _chaptersMap = {};

  bool get isLoaded => _loaded;
  List<Map<String, dynamic>> get religions => _religions;
  List<Map<String, dynamic>> get bookGroups => _bookGroups;
  List<Map<String, dynamic>> get books => _books;
  Map<String, int> get chaptersMap => _chaptersMap;

  /// 预加载学习数据（首页延迟调用）
  Future<void> preload() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('religions').select().eq('is_active', true).order('sort_order').order('name'),
        client.from('book_groups').select().order('created_at'),
        client.from('books').select().order('sort_order').order('title'),
        client.from('chapters').select('book_id').limit(1000),
      ]);
      
      if (results[0] is List) {
        _religions = List<Map<String, dynamic>>.from(results[0]);
      }
      if (results[1] is List) {
        _bookGroups = List<Map<String, dynamic>>.from(results[1]);
      }
      if (results[2] is List) {
        _books = List<Map<String, dynamic>>.from(results[2]);
      }
      if (results[3] is List) {
        _chaptersMap = {};
        for (final ch in results[3] as List) {
          final bookId = (ch as Map<String, dynamic>)['book_id']?.toString();
          if (bookId != null) {
            _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
          }
        }
      }
      _loaded = true;
    } catch (e) {
      // Preload failure is silent - learn screen will fetch on demand
    } finally {
      _loading = false;
    }
  }

  /// 清除缓存（用于强制刷新）
  void clear() {
    _loaded = false;
    _loading = false;
    _religions = [];
    _bookGroups = [];
    _books = [];
    _chaptersMap = {};
  }
}
