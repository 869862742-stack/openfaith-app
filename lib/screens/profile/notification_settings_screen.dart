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
  bool _soundEnabled = true;
  String _ringTone = 'gentle';
  String _messageTone = 'default';

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
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _ringTone = prefs.getString('ring_tone') ?? 'gentle';
      _messageTone = prefs.getString('message_tone') ?? 'default';
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setTone(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (!mounted) return;
    setState(() {});
  }

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
                gradient: AppColors.auroraGradient,
              ),
              padding: const EdgeInsets.all(1),
              child: Container(
                width: 46,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: AppColors.bgColor,
                ),
                padding: const EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 2),
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
                color: AppColors.borderColor,
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPlaceholder,
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
            // Notification permission banner with gradient border
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradient,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppColors.overlayBg,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: AppColors.auroraOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('通知权限',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text('允许发送通知以接收消息提醒',
                              style: TextStyle(
                                  color: AppColors.textWeak,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('通知权限设置请在系统设置中开启'),
                            backgroundColor: AppColors.cardBg,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('去开启',
                          style: TextStyle(
                              color: AppColors.auroraBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text('通知开关',
                        style: TextStyle(
                            color: AppColors.textWeak,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  _sectionCard(children: [
                    _settingItem(
                      icon: Icons.phone_android,
                      title: '来电提醒',
                      desc: '接收语音/视频通话提醒',
                      action: _buildToggle(
                        value: _callNotification,
                        onChanged: () {
                          setState(
                              () => _callNotification = !_callNotification);
                          _toggle('call_notification', _callNotification);
                        },
                      ),
                    ),
                    Container(
                        height: 1, color: AppColors.borderColor),
                    _settingItem(
                      icon: Icons.chat_bubble_outline,
                      title: '消息通知',
                      desc: '接收新消息通知',
                      action: _buildToggle(
                        value: _messageNotification,
                        onChanged: () {
                          setState(() => _messageNotification =
                              !_messageNotification);
                          _toggle(
                              'message_notification', _messageNotification);
                        },
                      ),
                    ),
                    Container(
                        height: 1, color: AppColors.borderColor),
                    _settingItem(
                      icon: Icons.volume_up,
                      title: '声音',
                      desc: '开启提示音',
                      action: _buildToggle(
                        value: _soundEnabled,
                        onChanged: () {
                          setState(() => _soundEnabled = !_soundEnabled);
                          _toggle('sound_enabled', _soundEnabled);
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text('声音设置',
                        style: TextStyle(
                            color: AppColors.textWeak,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  _sectionCard(children: [
                    GestureDetector(
                      onTap: () => _showTonePicker(
                        title: '选择来电铃声',
                        tones: _ringTones,
                        currentId: _ringTone,
                        prefKey: 'ring_tone',
                        icon: Icons.music_note,
                      ),
                      child: _settingItem(
                        icon: Icons.music_note,
                        title: '来电铃声',
                        desc: currentRingTone['name'],
                        action: const Icon(Icons.chevron_right,
                            color: AppColors.textWeak, size: 20),
                      ),
                    ),
                    Container(
                        height: 1, color: AppColors.borderColor),
                    GestureDetector(
                      onTap: () => _showTonePicker(
                        title: '选择消息提示音',
                        tones: _messageTones,
                        currentId: _messageTone,
                        prefKey: 'message_tone',
                        icon: Icons.volume_up,
                      ),
                      child: _settingItem(
                        icon: Icons.volume_up,
                        title: '消息提示音',
                        desc: currentMessageTone['name'],
                        action: const Icon(Icons.chevron_right,
                            color: AppColors.textWeak, size: 20),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
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
              color: AppColors.hoverBg,
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
                  Text(desc,
                      style: const TextStyle(
                          color: AppColors.textWeak, fontSize: 12)),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.hoverBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
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
                                  color: AppColors.hoverBg,
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
                                color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.hoverBg,
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
                  color: AppColors.hoverBg,
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
