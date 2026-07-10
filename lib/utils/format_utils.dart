/// 数量格式化工具函数（抖音风格 X万 / X亿）
///
/// 对齐网页版 formatCount() 实现：
/// < 10000       -> 原数字
/// >= 10000      -> 'X.X万'（保留1位小数）
/// >= 100000000  -> 'X.X亿'
String formatCount(int count) {
  if (count >= 100000000) {
    return '${(count / 100000000).toStringAsFixed(1)}亿';
  }
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}万';
  }
  return count.toString();
}
