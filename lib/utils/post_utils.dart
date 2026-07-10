/// 群聊检测工具函数 - 对齐网页版 postUtils.ts
/// 用于在 Supabase 查询后过滤掉群聊记录

/// 判断一个 post 是否是群聊
bool isGroupChat(Map<String, dynamic>? post) {
  if (post == null) return false;
  final tags = post['tags'];
  if (tags == null) return false;
  if (tags is List) {
    return tags.contains('__group_chat__');
  }
  return false;
}

/// 过滤掉群聊，获取纯笔记列表
List<Map<String, dynamic>> filterOutGroupChats(List<Map<String, dynamic>> posts) {
  return posts.where((post) => !isGroupChat(post)).toList();
}

/// 判断用户是否是群聊成员
bool isGroupMember(Map<String, dynamic>? post, String? userId) {
  if (post == null || userId == null) return false;
  final tags = post['tags'];
  if (tags == null) return false;
  if (tags is List) {
    return tags.contains('member_$userId');
  }
  return false;
}
