import 'package:flutter/material.dart';

/// 宗教/信仰标签图标映射 - 对齐网页版 ReligionIcon 组件
/// 为每个标签名分配一个 Material Icon 和颜色
class ReligionIconData {
  final IconData icon;
  final Color color;
  const ReligionIconData(this.icon, this.color);
}

const Map<String, ReligionIconData> _religionIconMap = {
  // 主流宗教
  '基督教':       ReligionIconData(Icons.church,                Color(0xFFFFD60A)),
  '天主教':       ReligionIconData(Icons.church_outlined,       Color(0xFFFFD60A)),
  '东正教':       ReligionIconData(Icons.church,                Color(0xFFFFD60A)),
  '伊斯兰教':     ReligionIconData(Icons.mosque,                Color(0xFF00E5FF)),
  '犹太教':       ReligionIconData(Icons.star,                  Color(0xFF3A86FF)),
  '佛教':         ReligionIconData(Icons.spa,                   Color(0xFFFF9F1C)),
  '印度教':       ReligionIconData(Icons.local_fire_department, Color(0xFFFF4D6D)),
  '道教':         ReligionIconData(Icons.balance,               Color(0xFF70E000)),
  '锡克教':       ReligionIconData(Icons.shield,                Color(0xFF9D4EDD)),

  // 亚伯拉罕系
  '巴哈伊教':     ReligionIconData(Icons.star_border,           Color(0xFFFFD60A)),
  '摩门教':       ReligionIconData(Icons.wb_sunny_outlined,     Color(0xFFFFD60A)),
  '耶和华见证人': ReligionIconData(Icons.tower,                 Color(0xFF3A86FF)),

  // 德鲁兹教 & 雅兹迪 & 曼达安
  '德鲁兹教':     ReligionIconData(Icons.star_half,             Color(0xFF00E5FF)),
  '雅兹迪':       ReligionIconData(Icons.wb_sunny,              Color(0xFFFFD60A)),
  '曼达安':       ReligionIconData(Icons.water,                 Color(0xFF00E5FF)),

  // 东亚 & 东盟
  '神道教':       ReligionIconData(Icons.architecture,          Color(0xFFFF4D6D)),
  '天理教':       ReligionIconData(Icons.emoji_events,          Color(0xFFFF9F1C)),
  '天道教':       ReligionIconData(Icons.self_improvement,      Color(0xFF3A86FF)),
  '高台教':       ReligionIconData(Icons.visibility,            Color(0xFFFFD60A)),
  '玛雅/阿兹特克': ReligionIconData(Icons.temple_hindu,         Color(0xFF70E000)),
  '毛利宗教':     ReligionIconData(Icons.waves,                 Color(0xFFFF4D6D)),

  // 南亚 & 中东
  '耆那教':       ReligionIconData(Icons.pan_tool,              Color(0xFFFF9F1C)),
  '琐罗亚斯德教': ReligionIconData(Icons.local_fire_department,  Color(0xFFFF9F1C)),
  '诺斯替':       ReligionIconData(Icons.psychology,            Color(0xFF9D4EDD)),
  '卡巴拉':       ReligionIconData(Icons.park,                  Color(0xFF70E000)),
  '约鲁巴教':     ReligionIconData(Icons.circle,                Color(0xFFFF4D6D)),
  '伏都教':       ReligionIconData(Icons.visibility,            Color(0xFF9D4EDD)),

  // 非宗教身份标签
  '宗教研究者':   ReligionIconData(Icons.menu_book,             Color(0xFF00E5FF)),
  '经文爱好者':   ReligionIconData(Icons.auto_stories,          Color(0xFF70E000)),
  '寻求者':       ReligionIconData(Icons.explore,               Color(0xFF9D4EDD)),
};

/// 获取标签对应的图标数据，支持模糊匹配
ReligionIconData getReligionIcon(String tagName) {
  // 精确匹配
  if (_religionIconMap.containsKey(tagName)) {
    return _religionIconMap[tagName]!;
  }

  // 模糊匹配：去掉括号内容
  final baseName = tagName.replaceAll(RegExp(r'[（(].+[)）]'), '').trim();
  if (baseName != tagName && _religionIconMap.containsKey(baseName)) {
    return _religionIconMap[baseName]!;
  }

  // 模糊匹配：检查 MAP 中的 key 是否被 tagName 包含
  for (final key in _religionIconMap.keys) {
    if (tagName.contains(key) || key.contains(tagName)) {
      return _religionIconMap[key]!;
    }
  }

  // 默认图标
  return const ReligionIconData(Icons.bookmark, Color(0x80FFFFFF));
}
