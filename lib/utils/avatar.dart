/// 默认头像和背景工具 - 对齐网页版 defaultImages.ts
///
/// 用法：
///   import '../../utils/avatar.dart';
///   final url = resolveAvatarUrl(userAvatarUrl, userId);

import 'dart:math';

// 七彩头像颜色列表（与网页版 AVATAR_NAMES 对齐）
const List<String> _avatarNames = [
  'red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'purple',
  'rose', 'tangerine', 'gold', 'lime', 'aqua', 'sky', 'violet',
];

// 背景名称列表（与网页版 BG_NAMES 对齐）
const List<String> _bgNames = ['default', 'deep', 'indigo', 'violet', 'ocean'];

/// 根据 seed（用户名/ID）生成确定性的 hash 值
int _computeHash(String seed) {
  int hash = 0;
  for (int i = 0; i < seed.length; i++) {
    hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
    // 保持 32 位整数范围，与 JS 行为一致
    hash = hash & 0x7FFFFFFF; // 取绝对值等效
    if (hash < 0) hash = -hash;
  }
  return hash;
}

/// 根据用户名/ID 生成确定性的默认头像 URL
/// 同一个输入总是返回同一个颜色
String getDefaultAvatarUrl(String seed) {
  if (seed.isEmpty) seed = 'default';
  final hash = _computeHash(seed);
  final idx = hash % _avatarNames.length;
  // 使用 UI Avatars API 作为默认头像方案
  final name = _avatarNames[idx];
  // 用颜色名映射到具体背景色
  const colorMap = {
    'red': 'E53E3E',
    'orange': 'ED8936',
    'yellow': 'ECC94B',
    'green': '48BB78',
    'cyan': '0BC5EA',
    'blue': '4299E5',
    'purple': '9F7AEA',
    'rose': 'ED64A6',
    'tangerine': 'F6AD55',
    'gold': 'D69E2E',
    'lime': '68D391',
    'aqua': '76E4F7',
    'sky': '63B3ED',
    'violet': 'B794F4',
  };
  final bg = colorMap[name] ?? '4299E5';
  return 'https://ui-avatars.com/api/?name=${name[0].toUpperCase()}&background=$bg&color=fff&size=128&bold=true';
}

/// 根据用户ID 生成确定性的默认背景 URL
String getDefaultBackgroundUrl(String seed) {
  if (seed.isEmpty) seed = 'default';
  final hash = _computeHash(seed);
  final idx = hash % _bgNames.length;
  return 'images/backgrounds/default-${_bgNames[idx]}.svg';
}

/// 获取头像 URL：有自定义头像返回自定义，否则返回默认
/// 对齐网页版 resolveAvatarUrl
String resolveAvatarUrl(String? avatarUrl, String? seed) {
  if (avatarUrl != null && avatarUrl.trim().isNotEmpty) return avatarUrl;
  return getDefaultAvatarUrl(seed ?? 'default');
}

/// 获取背景 URL：有自定义背景返回自定义，否则返回默认
String resolveBackgroundUrl(String? bgUrl, String? seed) {
  if (bgUrl != null && bgUrl.trim().isNotEmpty) return bgUrl;
  return getDefaultBackgroundUrl(seed ?? 'default');
}
