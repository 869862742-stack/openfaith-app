import 'package:flutter/material.dart';

/// OpenFaith 宗教主题表情列表 - 对齐网页版 EMOJI_ICONS
/// 用于评论、好友聊天、群聊中的表情互动
class EmojiIconItem {
  final IconData icon;
  final Color color;
  final String code;
  final String label;
  const EmojiIconItem({
    required this.icon,
    required this.color,
    required this.code,
    required this.label,
  });
}

const List<EmojiIconItem> emojiIcons = [
  EmojiIconItem(icon: Icons.sentiment_satisfied, color: Color(0xFFFFD93D), code: 'smile', label: '微笑'),
  EmojiIconItem(icon: Icons.sentiment_very_satisfied, color: Color(0xFFFFD93D), code: 'laugh', label: '大笑'),
  EmojiIconItem(icon: Icons.sentiment_dissatisfied, color: Color(0xFF74C0FC), code: 'frown', label: '难过'),
  EmojiIconItem(icon: Icons.thumb_up, color: Color(0xFF339AF0), code: 'thumbsup', label: '赞同'),
  EmojiIconItem(icon: Icons.favorite, color: Color(0xFFFF6B6B), code: 'heart', label: '爱心'),
  EmojiIconItem(icon: Icons.sentiment_very_dissatisfied, color: Color(0xFFFF6B6B), code: 'angry', label: '义怒'),
  EmojiIconItem(icon: Icons.church, color: Color(0xFFD0B28A), code: 'church', label: '教堂'),
  EmojiIconItem(icon: Icons.menu_book, color: Color(0xFFD0B28A), code: 'bookopen', label: '经文'),
  EmojiIconItem(icon: Icons.auto_stories, color: Color(0xFFF4D03F), code: 'scroll', label: '卷轴'),
  EmojiIconItem(icon: Icons.edit_note, color: Color(0xFF74C0FC), code: 'feather', label: '笔录'),
  EmojiIconItem(icon: Icons.key, color: Color(0xFFFFD43B), code: 'key', label: '天国钥匙'),
  EmojiIconItem(icon: Icons.flutter_dash, color: Color(0xFF74C0FC), code: 'bird', label: '和平'),
  EmojiIconItem(icon: Icons.auto_awesome, color: Color(0xFFFFD43B), code: 'sparkles', label: '恩膏'),
  EmojiIconItem(icon: Icons.local_fire_department, color: Color(0xFFFF922B), code: 'flame', label: '圣火'),
  EmojiIconItem(icon: Icons.air, color: Color(0xFF74C0FC), code: 'wind', label: '圣灵'),
  EmojiIconItem(icon: Icons.lightbulb, color: Color(0xFFFFD93D), code: 'lightbulb', label: '启示'),
  EmojiIconItem(icon: Icons.visibility, color: Color(0xFF339AF0), code: 'eye', label: '看见'),
  EmojiIconItem(icon: Icons.waves, color: Color(0xFF339AF0), code: 'waves', label: '活水'),
  EmojiIconItem(icon: Icons.wb_sunny, color: Color(0xFFFFD43B), code: 'sun', label: '真光'),
  EmojiIconItem(icon: Icons.wb_twilight, color: Color(0xFFFF922B), code: 'sunrise', label: '新生'),
  EmojiIconItem(icon: Icons.nightlight_round, color: Color(0xFFFFF3BF), code: 'moon', label: '沉思'),
  EmojiIconItem(icon: Icons.wb_cloudy, color: Color(0xFF74C0FC), code: 'cloudsun', label: '应许'),
  EmojiIconItem(icon: Icons.cloud, color: Color(0xFF5C7CFA), code: 'cloudmoon', label: '守望'),
  EmojiIconItem(icon: Icons.star, color: Color(0xFFFFD43B), code: 'star', label: '引导星'),
  EmojiIconItem(icon: Icons.local_florist, color: Color(0xFFF06595), code: 'flower', label: '绽放'),
  EmojiIconItem(icon: Icons.park, color: Color(0xFF51CF66), code: 'treepine', label: '生命树'),
  EmojiIconItem(icon: Icons.ac_unit, color: Color(0xFFE0F7FA), code: 'snowflake', label: '纯净'),
  EmojiIconItem(icon: Icons.grain, color: Color(0xFF868E96), code: 'cloudrain', label: '试炼'),
  EmojiIconItem(icon: Icons.handshake, color: Color(0xFFF06595), code: 'hearthandshake', label: '和解'),
  EmojiIconItem(icon: Icons.people, color: Color(0xFF51CF66), code: 'fellowship', label: '团契'),
  EmojiIconItem(icon: Icons.chat_bubble, color: Color(0xFF339AF0), code: 'message', label: '对话'),
  EmojiIconItem(icon: Icons.public, color: Color(0xFF339AF0), code: 'globe', label: '普世'),
  EmojiIconItem(icon: Icons.balance, color: Color(0xFFFFD43B), code: 'scale', label: '公义'),
  EmojiIconItem(icon: Icons.security, color: Color(0xFF339AF0), code: 'shield', label: '庇护'),
  EmojiIconItem(icon: Icons.card_giftcard, color: Color(0xFFFF6B6B), code: 'gift', label: '恩赐'),
  EmojiIconItem(icon: Icons.terrain, color: Color(0xFFA68A64), code: 'mountain', label: '坚定'),
  EmojiIconItem(icon: Icons.route, color: Color(0xFFFFD43B), code: 'route', label: '天路'),
  EmojiIconItem(icon: Icons.explore, color: Color(0xFFFF6B6B), code: 'compass', label: '指引'),
  EmojiIconItem(icon: Icons.signpost, color: Color(0xFF339AF0), code: 'signpost', label: '方向'),
  EmojiIconItem(icon: Icons.flag, color: Color(0xFFFF6B6B), code: 'flag', label: '旗帜'),
  EmojiIconItem(icon: Icons.emoji_events, color: Color(0xFFFFD43B), code: 'award', label: '冠冕'),
  EmojiIconItem(icon: Icons.account_balance, color: Color(0xFFFFD43B), code: 'landmark', label: '圣殿'),
];

/// 按 code 快速查找图标
final Map<String, EmojiIconItem> emojiIconMap = {
  for (final item in emojiIcons) item.code: item,
};
