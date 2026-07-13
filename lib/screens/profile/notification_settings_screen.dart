import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _callNotification = true;
  bool _messageNotification = true;
  bool _showNotificationContent = true;
  bool _messageSound = true;
  bool _callSound = true;
  String _ringTone = 'gentle';
  String _messageTone = 'default';
  String _callTone = 'gentle';

  static const _ringTones = [
    {'id': 'gentle', 'name': '柔和铃声', 'desc': '轻柔的提示音'},
    {'id': 'bright', 'name': '明亮铃声', 'desc': '清脆悦耳'},
    {'id': 'classic', 'name': '经典铃声', 'desc': '传统风格'},
    {'id': 'nature', 'name': '自然之声', 'desc': '鸟鸣与流水'},
  ];

  static const _messageTones = [
    {'id': 'default', 'name': '默认提示音', 'desc': '系统默认'},
    {'id': 'bubble', 'name': '气泡', 'desc': '轻快气泡声'},
    {'id': 'chime', 'name': '风铃', 'desc': '悠远风铃'},
    {'id': 'ping', 'name': '清脆', 'desc': '简洁提示'},
  ];

  static const _callTones = [
    {'id': 'gentle', 'name': '柔和铃声', 'desc': '轻柔的呼叫音'},
    {'id': 'bright', 'name': '明亮铃声', 'desc': '清脆悦耳'},
    {'id': 'classic', 'name': '经典铃声', 'desc': '传统风格'},
    {'id': 'nature', 'name': '自然之声', 'desc': '鸟鸣与流水'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _callNotification = prefs.getBool('call_notification') ?? true;
      _messageNotification = prefs.getBool('message_notification') ?? true;
      _showNotificationContent = prefs.getBool('show_notification_content') ?? true;
      _messageSound = prefs.getBool('message_sound') ?? true;
      _callSound = prefs.getBool('call_sound') ?? true;
      _ringTone = prefs.getString('ring_tone') ?? 'gentle';
      _messageTone = prefs.getString('message_tone') ?? 'default';
      _callTone = prefs.getString('call_tone') ?? 'gentle';
    });
  }

  Future<void> _toggleBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setTone(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (!mounted) return;
    setState(() {});
  }

  /// Toggle switch matching web style:
  /// enabled: 2px transparent border + rainbow gradient border (outer gradient + inner dark bg)
  /// disabled: gray bg + slight border
  Widget _buildToggle({
    required bool value,
    required VoidCallback onChanged,
  }) {
    return GestureDetector(
      onTap: onChanged,
      child: value
          ? Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: AppColors.rainbowEnd, width: 1),

              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.bgColor,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textPrimary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0x26FFFFFF), // rgba(255,255,255,0.15)
                border: Border.all(
                  color: const Color(0x1AFFFFFF), // rgba(255,255,255,0.1)
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x66FFFFFF), // rgba(255,255,255,0.4)
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRingTone = _ringTones.firstWhere(
      (t) => t['id'] == _ringTone,
      orElse: () => _ringTones[0],
    );
    final currentMessageTone = _messageTones.firstWhere(
      (t) => t['id'] == _messageTone,
      orElse: () => _messageTones[0],
    );
    final currentCallTone = _callTones.firstWhere(
      (t) => t['id'] == _callTone,
      orElse: () => _callTones[0],
    );

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('通知设置',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // ===== 消息通知 =====
            _sectionTitle('消息通知'),
            _sectionCard(children: [
              _settingItem(
                icon: Icons.message_outlined,
                title: '新消息通知',
                desc: '收到新消息时提醒',
                action: _buildToggle(
                  value: _messageNotification,
                  onChanged: () {
                    setState(() => _messageNotification = !_messageNotification);
                    _toggleBool('message_notification', _messageNotification);
                  },
                ),
              ),
              _divider(),
              _settingItem(
                icon: Icons.phone_outlined,
                title: '语音和视频通话通知',
                desc: '收到通话邀请时响铃提醒',
                action: _buildToggle(
                  value: _callNotification,
                  onChanged: () {
                    setState(() => _callNotification = !_callNotification);
                    _toggleBool('call_notification', _callNotification);
                  },
                ),
              ),
            ]),

            // ===== 通知显示 =====
            _sectionTitle('通知显示'),
            _sectionCard(children: [
              _settingItem(
                icon: Icons.visibility_outlined,
                title: '通知显示内容',
                desc: _showNotificationContent
                    ? '显示发送者和消息内容'
                    : '隐藏消息内容，保护隐私',
                action: _buildToggle(
                  value: _showNotificationContent,
                  onChanged: () {
                    setState(() => _showNotificationContent = !_showNotificationContent);
                    _toggleBool('show_notification_content', _showNotificationContent);
                  },
                ),
              ),
            ]),

            // ===== 声音与震动 =====
            _sectionTitle('声音与震动'),
            _sectionCard(children: [
              _settingItem(
                icon: Icons.volume_up_outlined,
                title: '消息提示音',
                desc: '收到新消息时播放提示音',
                action: _buildToggle(
                  value: _messageSound,
                  onChanged: () {
                    setState(() => _messageSound = !_messageSound);
                    _toggleBool('message_sound', _messageSound);
                  },
                ),
              ),
              _divider(),
              _settingItem(
                icon: Icons.music_note_outlined,
                title: '通话铃声',
                desc: '收到通话邀请时播放铃声',
                action: _buildToggle(
                  value: _callSound,
                  onChanged: () {
                    setState(() => _callSound = !_callSound);
                    _toggleBool('call_sound', _callSound);
                  },
                ),
              ),
            ]),

            // ===== 提示音与铃声 =====
            _sectionTitle('提示音与铃声'),
            _sectionCard(children: [
              GestureDetector(
                onTap: () => _showTonePicker(
                  title: '选择消息提示音',
                  tones: _messageTones,
                  currentId: _messageTone,
                  prefKey: 'message_tone',
                  icon: Icons.message_outlined,
                ),
                child: _settingItem(
                  icon: Icons.message_outlined,
                  title: '消息提示音',
                  desc: currentMessageTone['name'],
                  action: const Icon(Icons.chevron_right,
                      color: AppColors.textPlaceholder, size: 20),
                ),
              ),
              _divider(),
              GestureDetector(
                onTap: () => _showTonePicker(
                  title: '选择来电铃声',
                  tones: _ringTones,
                  currentId: _ringTone,
                  prefKey: 'ring_tone',
                  icon: Icons.phone_outlined,
                ),
                child: _settingItem(
                  icon: Icons.phone_outlined,
                  title: '来电铃声',
                  desc: currentRingTone['name'],
                  action: const Icon(Icons.chevron_right,
                      color: AppColors.textPlaceholder, size: 20),
                ),
              ),
              _divider(),
              GestureDetector(
                onTap: () => _showTonePicker(
                  title: '选择呼叫铃声',
                  tones: _callTones,
                  currentId: _callTone,
                  prefKey: 'call_tone',
                  icon: Icons.phone_callback_outlined,
                ),
                child: _settingItem(
                  icon: Icons.phone_callback_outlined,
                  title: '呼叫铃声',
                  desc: currentCallTone['name'],
                  action: const Icon(Icons.chevron_right,
                      color: AppColors.textPlaceholder, size: 20),
                ),
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0x66FFFFFF), // rgba(255,255,255,0.4)
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    String? desc,
    required Widget action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                if (desc != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(desc,
                        style: const TextStyle(
                            color: AppColors.textWeak, fontSize: 12)),
                  ),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0FFFFFFF)), // rgba(255,255,255,0.06)
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  void _showTonePicker({
    required String title,
    required List<Map<String, String>> tones,
    required String currentId,
    required String prefKey,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...tones.map((tone) {
              final isSelected = currentId == tone['id'];
              return GestureDetector(
                onTap: () async {
                  setState(() {
                    if (prefKey == 'ring_tone') {
                      _ringTone = tone['id']!;
                    } else if (prefKey == 'call_tone') {
                      _callTone = tone['id']!;
                    } else {
                      _messageTone = tone['id']!;
                    }
                  });
                  await _setTone(prefKey, tone['id']!);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient:
                        isSelected ? AppColors.auroraGradient : null,
                  ),
                  child: isSelected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: AppColors.bgColor,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(icon,
                                    color: AppColors.textPrimary,
                                    size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(tone['name']!,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w500)),
                                    Text(tone['desc']!,
                                        style: const TextStyle(
                                            color: AppColors.textWeak,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.auroraGreen,
                                      AppColors.auroraCyan,
                                    ],
                                  ),
                                ),
                                child: const Icon(Icons.check,
                                    color: AppColors.textPrimary,
                                    size: 12),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: AppColors.bgColor,
                            border: Border.all(
                                color: const Color(0x0FFFFFFF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(icon,
                                    color: AppColors.textPrimary,
                                    size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(tone['name']!,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w500)),
                                    Text(tone['desc']!,
                                        style: const TextStyle(
                                            color: AppColors.textWeak,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              );
            }),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('完成',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
