import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_starfield.dart';
import '../../widgets/aurora_button.dart';
import '../../widgets/rainbow_border.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// ════════════════════════════════════════════════════════════════
// 数据模型
// ════════════════════════════════════════════════════════════════

/// 音频轨道
class AudioTrack {
  final String id;
  final String name;
  final String url;
  final double? duration;
  final String? lyrics;
  final String? cachedLrc;
  final String uploadedAt;

  AudioTrack({
    required this.id,
    required this.name,
    required this.url,
    this.duration,
    this.lyrics,
    this.cachedLrc,
    required this.uploadedAt,
  });

  AudioTrack copyWith({
    String? id,
    String? name,
    String? url,
    double? duration,
    String? lyrics,
    String? cachedLrc,
    String? uploadedAt,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      lyrics: lyrics ?? this.lyrics,
      cachedLrc: cachedLrc ?? this.cachedLrc,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        if (duration != null) 'duration': duration,
        if (lyrics != null) 'lyrics': lyrics,
        'uploaded_at': uploadedAt,
      };

  factory AudioTrack.fromJson(Map<String, dynamic> json) => AudioTrack(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '未知曲目',
        url: json['url']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toDouble(),
        lyrics: json['lyrics']?.toString(),
        cachedLrc: json['cachedLrc']?.toString(),
        uploadedAt: json['uploaded_at']?.toString() ?? '',
      );
}

/// 房间参与者
class RoomParticipant {
  final String id;
  final String userId;
  final String status;
  final bool isOwner;
  final String joinedAt;
  final String? username;
  final String? avatarUrl;
  final String? faithTag;

  RoomParticipant({
    required this.id,
    required this.userId,
    required this.status,
    required this.isOwner,
    required this.joinedAt,
    this.username,
    this.avatarUrl,
    this.faithTag,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return RoomParticipant(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'quiet',
      isOwner: json['is_owner'] == true,
      joinedAt: json['joined_at']?.toString() ?? '',
      username: profiles?['username']?.toString(),
      avatarUrl: profiles?['avatar_url']?.toString(),
      faithTag: profiles?['faith_tag']?.toString(),
    );
  }
}

/// 轻语句子
class FloatingSentence {
  final String id;
  final String content;
  final String userId;
  final String createdAt;
  final String? username;
  final String? avatarUrl;

  FloatingSentence({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });

  factory FloatingSentence.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return FloatingSentence(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      username: profiles?['username']?.toString(),
      avatarUrl: profiles?['avatar_url']?.toString(),
    );
  }
}

/// LRC 歌词行
class LrcLine {
  final double time;
  final String text;
  LrcLine({required this.time, required this.text});
}

/// 播放模式
enum PlayMode { list, single, shuffle }

// ════════════════════════════════════════════════════════════════
// LRC 解析工具
// ════════════════════════════════════════════════════════════════

List<LrcLine> parseLrc(String lrcText) {
  final lines = lrcText.split('\n');
  final result = <LrcLine>[];
  final timeRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\]');

  for (final line in lines) {
    final matches = timeRegex.allMatches(line);
    if (matches.isEmpty) continue;

    final text = line.replaceAll(RegExp(r'\[\d{2}:\d{2}(?:\.\d{2,3})?\]'), '').trim();
    if (text.isEmpty) continue;

    for (final match in matches) {
      final min = int.parse(match.group(1) ?? '0');
      final sec = int.parse(match.group(2) ?? '0');
      final msStr = match.group(3) ?? '0';
      final ms = int.parse(msStr.padRight(3, '0'));
      final time = min * 60.0 + sec + ms / 1000.0;
      result.add(LrcLine(time: time, text: text));
    }
  }

  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}

bool isLrcFormat(String text) => RegExp(r'\[\d{2}:\d{2}').hasMatch(text);

/// 从 Python dict 格式字符串中提取纯文本
/// 处理类似 {"text": "hello", "translated": "你好"} 的格式
String extractTextFromDictFormat(String text) {
  if (!text.trimLeft().startsWith('{')) return text;
  try {
    final decoded = jsonDecode(text.replaceAll('\'', '\"'));
    if (decoded is Map<String, dynamic>) {
      final buffer = StringBuffer();
      for (final value in decoded.values) {
        if (value is String && value.isNotEmpty) {
          buffer.writeln(value);
        }
      }
      return buffer.toString().trim();
    }
  } catch (_) {}
  return text;
}

/// 将 dict 格式歌词转换为 LRC 格式
String convertDictToLrc(String text) {
  if (!text.contains(':') || !text.contains('{')) return text;
  // 如果不是 LRC 格式但包含时间戳的 dict，尝试转换
  try {
    final lines = text.split('\n');
    final lrcLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('{') && trimmed.contains('time')) {
        final decoded = jsonDecode(trimmed.replaceAll('\'', '\"')) as Map<String, dynamic>;
        final time = decoded['time'];
        final content = decoded['content'] ?? decoded['text'] ?? '';
        if (time is num && content is String && content.isNotEmpty) {
          final totalSec = time.toDouble();
          final min = (totalSec ~/ 60).toString().padLeft(2, '0');
          final sec = (totalSec % 60).toStringAsFixed(2).padLeft(5, '0');
          lrcLines.add('[$min:$sec]$content');
        }
      } else if (trimmed.isNotEmpty) {
        lrcLines.add(trimmed);
      }
    }
    return lrcLines.join('\n');
  } catch (_) {}
  return text;
}

// ════════════════════════════════════════════════════════════════
// 状态选项
// ════════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> statusOptions = [
  {'value': 'quiet', 'label': '安静中', 'icon': Icons.nights_stay},
  {'value': 'reading', 'label': '阅读中', 'icon': Icons.menu_book},
  {'value': 'reflecting', 'label': '反思中', 'icon': Icons.favorite},
  {'value': 'meditating', 'label': '冥想中', 'icon': Icons.psychology},
  {'value': 'praying', 'label': '祈祷中', 'icon': Icons.self_improvement},
  {'value': 'grateful', 'label': '感恩中', 'icon': Icons.auto_awesome},
];

// ════════════════════════════════════════════════════════════════
// SilentRoomScreen
// ════════════════════════════════════════════════════════════════

class SilentRoomScreen extends StatefulWidget {
  final String roomId;

  const SilentRoomScreen({super.key, required this.roomId});

  @override
  State<SilentRoomScreen> createState() => _SilentRoomScreenState();
}

class _SilentRoomScreenState extends State<SilentRoomScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  final _audioPlayer = AudioPlayer();
  final _sentenceCtrl = TextEditingController();
  final _lyricsScrollCtrl = ScrollController();

  // ── 房间数据 ──
  Map<String, dynamic>? _room;
  List<RoomParticipant> _participants = [];
  List<FloatingSentence> _sentences = [];
  List<AudioTrack> _audioTracks = [];

  // ── 用户状态 ──
  String? _currentUserId;
  String _currentStatus = 'quiet';
  bool _isLoading = true;
  String? _error;

  // ── 音频播放状态 ──
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  bool _isMuted = false;
  PlayMode _playMode = PlayMode.list;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // ── UI 状态 ──
  bool _showSentenceInput = false;
  bool _showSoundPanel = false;
  bool _showLyrics = false;
  bool _showDisbandConfirm = false;
  bool _showStatusPicker = false;
  bool _showMembersSheet = false;
  bool _uploadingAudio = false;
  String _uploadProgress = '';

  // ── 浮动面板状态 ──
  Offset _soundPanelPosition = const Offset(20, 100);
  bool _isSoundPanelMinimized = false;
  final double _soundPanelWidth = 300;

  // ── 定时器 ──
  Timer? _dataRefreshTimer;
  Timer? _heartbeatTimer;
  Timer? _sentenceExpiryTimer;

  // ── 动画 ──
  late AnimationController _floatController;

  // ── 漂浮句子偏移 ──
  final List<double> _sentenceOffsets = [];
  final Random _rng = Random();

  bool get _isOwner =>
      _room?['creator_id']?.toString() == _currentUserId;

  AudioTrack? get _currentTrack =>
      _audioTracks.isNotEmpty && _currentTrackIndex < _audioTracks.length
          ? _audioTracks[_currentTrackIndex]
          : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _currentUserId = _supabase.auth.currentUser?.id;
    _initAudioListener();
    _initRoom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataRefreshTimer?.cancel();
    _heartbeatTimer?.cancel();
    _sentenceExpiryTimer?.cancel();
    _floatController.dispose();
    _audioPlayer.dispose();
    _sentenceCtrl.dispose();
    _lyricsScrollCtrl.dispose();
    _leaveRoom();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _leaveRoom();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 初始化
  // ══════════════════════════════════════════════════════════════

  void _initAudioListener() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => _totalDuration = dur);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _handleTrackComplete();
    });
  }

  Future<void> _initRoom() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _fetchRoom();
      await _joinRoom();
      await _fetchParticipants();
      await _fetchSentences();

      // 定时刷新数据
      _dataRefreshTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _refreshData(),
      );

      // 心跳
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => _sendHeartbeat(),
      );

      // 句子过期清理
      _sentenceExpiryTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _cleanExpiredSentences(),
      );
    } catch (e, s) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      Sentry.captureException(e, stackTrace: s);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _fetchParticipants();
    await _fetchSentences();
    await _checkRoomCleanup();
  }

  // ══════════════════════════════════════════════════════════════
  // 数据访问
  // ══════════════════════════════════════════════════════════════

  Future<void> _fetchRoom() async {
    final data = await _supabase
        .from('rooms')
        .select()
        .eq('id', widget.roomId)
        .maybeSingle();
    if (data == null) throw Exception('房间不存在');
    if (!mounted) return;
    setState(() => _room = Map<String, dynamic>.from(data));

    // 解析音频轨道
    final tracksData = data['audio_tracks'];
    if (tracksData is List && tracksData.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _audioTracks = tracksData
            .whereType<Map>()
            .map((t) => AudioTrack.fromJson(Map<String, dynamic>.from(t)))
            .toList();
      });
    } else if (data['custom_audio_url'] != null) {
      if (!mounted) return;
      setState(() {
        _audioTracks = [
          AudioTrack(
            id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
            name: '自定义音频',
            url: data['custom_audio_url'].toString(),
            uploadedAt: DateTime.now().toIso8601String(),
          ),
        ];
      });
    }
  }

  Future<void> _fetchParticipants() async {
    try {
      final data = await _supabase
          .from('room_participants')
          .select('*, profiles(username, avatar_url, faith_tag)')
          .eq('room_id', widget.roomId)
          .order('joined_at', ascending: true);
      if (data != null && mounted) {
        if (!mounted) return;
        setState(() {
          _participants = data
              .whereType<Map>()
              .map((d) => RoomParticipant.fromJson(Map<String, dynamic>.from(d)))
              .toList();
        });
      }
    } catch (e) { debugPrint('加载房间参与者失败: $e'); }
  }

  Future<void> _fetchSentences() async {
    try {
      final fiveMinAgo =
          DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      final data = await _supabase
          .from('room_sentences')
          .select('*, profiles(username, avatar_url)')
          .eq('room_id', widget.roomId)
          .gte('created_at', fiveMinAgo)
          .order('created_at', ascending: false)
          .limit(10);
      if (data != null && mounted) {
        final sentences = data
            .whereType<Map>()
            .map((d) => FloatingSentence.fromJson(Map<String, dynamic>.from(d)))
            .toList();
        if (!mounted) return;
        setState(() {
          _sentences = sentences.take(5).toList();
          while (_sentenceOffsets.length < _sentences.length) {
            _sentenceOffsets.add(_rng.nextDouble());
          }
        });
      }
    } catch (e) { debugPrint('加载最近聊天消息失败: $e'); }
  }

  void _cleanExpiredSentences() {
    final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final before = _sentences.length;
    setState(() {
      _sentences.removeWhere((s) {
        final createdAt = DateTime.tryParse(s.createdAt);
        return createdAt != null && createdAt.isBefore(fiveMinAgo);
      });
    });
    if (_sentences.length != before && mounted) {
      setState(() {});
    }
  }

  Future<void> _joinRoom() async {
    if (_currentUserId == null) return;
    try {
      final existing = await _supabase
          .from('room_participants')
          .select('id')
          .eq('room_id', widget.roomId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();
      if (existing == null) {
        await _supabase.from('room_participants').insert({
          'room_id': widget.roomId,
          'user_id': _currentUserId,
          'is_owner': _room?['creator_id']?.toString() == _currentUserId,
          'status': 'quiet',
        });
      }
    } catch (e) { debugPrint('加入房间失败: $e'); }

  }
  Future<void> _leaveRoom() async {
    if (_currentUserId == null) return;
    try {
      await _supabase
          .from('room_participants')
          .delete()
          .eq('room_id', widget.roomId)
          .eq('user_id', _currentUserId!);
    } catch (e) { debugPrint('退出房间失败: $e'); }
  }

  Future<void> _sendHeartbeat() async {
    if (_currentUserId == null) return;
    try {
      await _supabase
          .from('room_participants')
          .update({
            'last_active_at': DateTime.now().toIso8601String(),
            'status': _currentStatus,
          })
          .eq('room_id', widget.roomId)
          .eq('user_id', _currentUserId!);
    } catch (e) { debugPrint('发送房间心跳失败: $e'); }
  }

  Future<void> _checkRoomCleanup() async {
    try {
      final room = await _supabase
          .from('rooms')
          .select('last_activity_at, user_count')
          .eq('id', widget.roomId)
          .maybeSingle();
      if (room == null) {
        // 房间已被删除
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final lastActivity = room['last_activity_at'] != null
          ? DateTime.tryParse(room['last_activity_at'].toString())
          : null;
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      if ((room['user_count'] as int? ?? 0) == 0 &&
          lastActivity != null &&
          lastActivity.isBefore(oneHourAgo)) {
        await _disbandRoom();
      }
    } catch (e) { debugPrint('检查房间活跃状态失败: $e'); }
  }

  Future<void> _syncParticipantCount() async {
    if (_participants.isEmpty) return;
    try {
      await _supabase
          .from('rooms')
          .update({'user_count': _participants.length})
          .eq('id', widget.roomId);
    } catch (e) { debugPrint('更新房间人数失败: $e'); }
  }

  // ══════════════════════════════════════════════════════════════
  // 状态管理
  // ══════════════════════════════════════════════════════════════

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _currentStatus = newStatus);
    if (_currentUserId == null) return;
    try {
      await _supabase
          .from('room_participants')
          .update({'status': newStatus})
          .eq('room_id', widget.roomId)
          .eq('user_id', _currentUserId!);
    } catch (e) { debugPrint('更新参与者状态失败: $e'); }
  }

  // ══════════════════════════════════════════════════════════════
  // 轻语发送
  // ══════════════════════════════════════════════════════════════

  Future<void> _sendSentence() async {
    final text = _sentenceCtrl.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    try {
      await _supabase.from('room_sentences').insert({
        'room_id': widget.roomId,
        'user_id': _currentUserId,
        'content': text.substring(0, text.length.clamp(0, 200)),
      });
      _sentenceCtrl.clear();
      if (!mounted) return;
      setState(() => _showSentenceInput = false);
      await _fetchSentences();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 音频控制
  // ══════════════════════════════════════════════════════════════

  Future<void> _playTrack([String? url]) async {
    if (_audioTracks.isEmpty) return;
    final trackUrl = url ?? _currentTrack?.url;
    if (trackUrl == null) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(UrlSource(trackUrl));
      await _audioPlayer.setVolume(_isMuted ? 0.0 : 0.5);
      await _audioPlayer.resume();
    } catch (e, s) {
      debugPrint('Audio play error: $e');
      Sentry.captureException(e, stackTrace: s);
    }
  }

  Future<void> _pauseTrack() async {
    await _audioPlayer.pause();
  }

  Future<void> _resumeTrack() async {
    if (_audioPlayer.state == PlayerState.paused) {
      await _audioPlayer.setVolume(_isMuted ? 0.0 : 0.5);
      await _audioPlayer.resume();
    } else if (_audioTracks.isNotEmpty) {
      await _playTrack();
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseTrack();
    } else {
      _resumeTrack();
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _audioPlayer.setVolume(_isMuted ? 0.0 : 0.5);
  }

  void _cyclePlayMode() {
    setState(() {
      switch (_playMode) {
        case PlayMode.list:
          _playMode = PlayMode.single;
          break;
        case PlayMode.single:
          _playMode = PlayMode.shuffle;
          break;
        case PlayMode.shuffle:
          _playMode = PlayMode.list;
          break;
      }
    });
  }

  void _handleTrackComplete() {
    if (_audioTracks.isEmpty) return;
    switch (_playMode) {
      case PlayMode.single:
        _playTrack();
        break;
      case PlayMode.shuffle:
        int nextIndex = _rng.nextInt(_audioTracks.length);
        if (nextIndex == _currentTrackIndex && _audioTracks.length > 1) {
          nextIndex = (nextIndex + 1) % _audioTracks.length;
        }
        setState(() => _currentTrackIndex = nextIndex);
        _playTrack(_audioTracks[nextIndex].url);
        break;
      case PlayMode.list:
        final nextIndex = (_currentTrackIndex + 1) % _audioTracks.length;
        setState(() => _currentTrackIndex = nextIndex);
        _playTrack(_audioTracks[nextIndex].url);
        break;
    }
  }

  void _playPrevious() {
    if (_audioTracks.isEmpty) return;
    final newIndex =
        _currentTrackIndex == 0 ? _audioTracks.length - 1 : _currentTrackIndex - 1;
    setState(() => _currentTrackIndex = newIndex);
    if (_isPlaying) {
      _playTrack(_audioTracks[newIndex].url);
    }
  }

  void _playNext() {
    if (_audioTracks.isEmpty) return;
    final newIndex = (_currentTrackIndex + 1) % _audioTracks.length;
    setState(() => _currentTrackIndex = newIndex);
    if (_isPlaying) {
      _playTrack(_audioTracks[newIndex].url);
    }
  }

  void _seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  // ══════════════════════════════════════════════════════════════
  // 房间管理
  // ══════════════════════════════════════════════════════════════

  Future<void> _disbandRoom() async {
    try {
      await _supabase
          .from('room_participants')
          .delete()
          .eq('room_id', widget.roomId);
      await _supabase
          .from('room_sentences')
          .delete()
          .eq('room_id', widget.roomId);
      await _supabase.from('rooms').delete().eq('id', widget.roomId);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解散房间失败: $e')),
        );
      }
    }
  }

  Future<void> _kickParticipant(String userId) async {
    try {
      await _supabase
          .from('room_participants')
          .delete()
          .eq('room_id', widget.roomId)
          .eq('user_id', userId);
      await _fetchParticipants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除成员失败: $e')),
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    if (!_isOwner) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _uploadingAudio = true;
        _uploadProgress = '上传中 0/${result.files.length}...';
      });

      final newTracks = <AudioTrack>[];

      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (mounted) {
          setState(() => _uploadProgress = '上传中 ${i + 1}/${result.files.length}...');
        }

        if (file.size > 20 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('文件 ${file.name} 超过20MB限制')),
            );
          }
          continue;
        }

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final filePath = 'room-audio/${widget.roomId}/$fileName';

        try {
          // 提取音频文件元数据
          String trackName = file.name.replaceAll(RegExp(r'\.[^/.]+$'), '');
          String? artistName;
          String? extractedLyrics;
          double? trackDuration;

          try {
            final audioFile = File(file.path!);
            final metadata = readMetadata(audioFile, getImage: false);
            
            if (metadata.title != null && metadata.title!.isNotEmpty) {
              trackName = metadata.title!;
            }
            if (metadata.artist != null && metadata.artist!.isNotEmpty) {
              artistName = metadata.artist;
            }
            if (metadata.lyrics != null && metadata.lyrics!.isNotEmpty) {
              extractedLyrics = metadata.lyrics;
            }
            if (metadata.duration != null) {
              trackDuration = metadata.duration!.inMilliseconds / 1000.0;
            }
            debugPrint('Metadata extracted: title=$trackName, artist=$artistName, duration=$trackDuration');
          } catch (metaError) {
            debugPrint('Failed to extract metadata: $metaError');
          }

          // 上传文件到存储
          final audioFile = File(file.path!);
          await _supabase.storage.from('media').upload(filePath, audioFile);
          final audioUrl =
              _supabase.storage.from('media').getPublicUrl(filePath);

          // 如果有艺术家信息，显示为 "歌曲名 - 艺术家"
          final displayName = artistName != null && artistName.isNotEmpty
              ? '$trackName - $artistName'
              : trackName;

          newTracks.add(AudioTrack(
            id: '${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999999)}',
            name: displayName,
            url: audioUrl,
            duration: trackDuration,
            lyrics: extractedLyrics,
            uploadedAt: DateTime.now().toIso8601String(),
          ));
        } catch (e, s) {
          debugPrint('Upload error for ${file.name}: $e');
          Sentry.captureException(e, stackTrace: s);
        }
      }

      if (newTracks.isNotEmpty) {
        final updatedTracks = [..._audioTracks, ...newTracks];
        if (!mounted) return;
        setState(() => _audioTracks = updatedTracks);
        await _updateAudioTracksInDb(updatedTracks);

        // 自动播放第一首
        if (!_isPlaying && _audioTracks.isNotEmpty) {
          _playTrack(newTracks.first.url);
        }
      }
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _uploadingAudio = false;
        _uploadProgress = '';
      });
    }
  }

  Future<void> _updateAudioTracksInDb(List<AudioTrack> tracks) async {
    try {
      await _supabase
          .from('rooms')
          .update({
            'audio_tracks': tracks.map((t) => t.toJson()).toList(),
          })
          .eq('id', widget.roomId);
    } catch (e) { debugPrint('同步音频轨道数据失败: $e'); }
  }

  Future<void> _deleteAudioTrack(String trackId) async {
    final updatedTracks =
        _audioTracks.where((t) => t.id != trackId).toList();
    setState(() => _audioTracks = updatedTracks);

    if (_audioTracks.isNotEmpty &&
        _currentTrackIndex >= _audioTracks.length) {
      setState(() => _currentTrackIndex = 0);
    }

    if (_currentTrack?.id == trackId && _isPlaying) {
      await _audioPlayer.stop();
    }

    await _updateAudioTracksInDb(updatedTracks);
  }

  // ══════════════════════════════════════════════════════════════
  // 分享
  // ══════════════════════════════════════════════════════════════

  void _shareRoom() {
    final roomCode = _room?['room_code'];
    final message = roomCode != null
        ? '来和我一起共境吧！房间ID: $roomCode'
        : '来和我一起共境吧！';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('分享信息: $message'),
        backgroundColor: AppColors.overlayBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 歌词解析
  // ══════════════════════════════════════════════════════════════

  ({bool isLrc, List<LrcLine> lines, String rawText}) _getParsedLyrics() {
    final track = _currentTrack;
    if (track == null) {
      return (isLrc: false, lines: <LrcLine>[], rawText: '');
    }

    // 优先使用缓存的在线LRC
    var lrcText = track.cachedLrc ?? track.lyrics;
    if (lrcText == null || lrcText.isEmpty) {
      return (isLrc: false, lines: <LrcLine>[], rawText: '');
    }

    // 预处理：处理 Python dict 格式歌词（对齐网页版 extractTextFromDictFormat）
    lrcText = extractTextFromDictFormat(lrcText);
    lrcText = convertDictToLrc(lrcText);

    if (isLrcFormat(lrcText)) {
      return (isLrc: true, lines: parseLrc(lrcText), rawText: lrcText);
    }
    return (isLrc: false, lines: <LrcLine>[], rawText: lrcText);
  }

  int _getActiveLyricIndex(List<LrcLine> lines) {
    if (lines.isEmpty) return -1;
    final currentTimeSec = _currentPosition.inMilliseconds / 1000.0;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentTimeSec >= lines[i].time) return i;
    }
    return -1;
  }

  // ══════════════════════════════════════════════════════════════
  // 格式化
  // ══════════════════════════════════════════════════════════════

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String _getPlayModeLabel() {
    switch (_playMode) {
      case PlayMode.list:
        return '列表循环';
      case PlayMode.single:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机播放';
    }
  }

  IconData _getPlayModeIcon() {
    switch (_playMode) {
      case PlayMode.list:
        return Icons.repeat;
      case PlayMode.single:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  String _getStatusLabel(String value) {
    return statusOptions
            .firstWhere((s) => s['value'] == value, orElse: () => statusOptions[0])
        ['label'] as String;
  }

  // ══════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.nights_stay, color: AppColors.auroraCyan, size: 40),
              const SizedBox(height: 16),
              Text(
                '进入静默空间...',
                style: TextStyle(color: AppColors.textWeak, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😔', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AuroraButton(
                  text: '返回',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedStarfield(
        child: Stack(
          children: [
            _buildBody(),
            if (_showSoundPanel) _buildSoundPanel(),
            if (_showDisbandConfirm) _buildDisbandDialog(),
            if (_showStatusPicker) _buildStatusPicker(),
            if (_showMembersSheet) _buildMembersSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                // 漂浮句子
                _buildFloatingSentences(),
                // 成员头像漂浮
                if (_participants.isNotEmpty) _buildFloatingAvatars(),
                // 歌词显示
                if (_showLyrics && _currentTrack != null) _buildLyricsOverlay(),
              ],
            ),
          ),
          // 底部操作区
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 顶部导航栏
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    final roomName = _room?['name']?.toString() ?? '房间';
    final roomCode = _room?['room_code'];
    final memberCount =
        _participants.isNotEmpty ? _participants.length : (_room?['user_count'] as int? ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
            ),
          ),
          // 房间信息
          Expanded(
            child: Column(
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (roomCode != null)
                  Text(
                    'ID: $roomCode',
                    style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 11),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.nights_stay, color: AppColors.auroraCyan, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$memberCount 人在此',
                      style: const TextStyle(color: AppColors.textWeak, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 分享按钮
          GestureDetector(
            onTap: _shareRoom,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 漂浮句子
  // ══════════════════════════════════════════════════════════════

  Widget _buildFloatingSentences() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: List.generate(_sentences.length, (i) {
                final sentence = _sentences[i];
                final offset = i < _sentenceOffsets.length
                    ? _sentenceOffsets[i]
                    : 0.5;
                final progress = (_floatController.value + offset) % 1.0;
                final yStart = constraints.maxHeight * 0.55;
                final yOffset = progress * 200;
                final opacity = progress < 0.05
                    ? progress / 0.05
                    : progress > 0.9
                        ? (1.0 - progress) / 0.1
                        : 1.0;
                final xBase = offset * (constraints.maxWidth - 240) + 20;

                return Positioned(
                  left: xBase,
                  top: yStart - yOffset,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderDefault,
                        ),
                      ),
                      child: Text(
                        sentence.content,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 成员头像漂浮
  // ══════════════════════════════════════════════════════════════

  Widget _buildFloatingAvatars() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Positioned(
              top: constraints.maxHeight * 0.7,
              left: 0,
              right: 0,
              height: 48,
              child: ClipRect(
                child: Stack(
                  children: List.generate(_participants.length.clamp(0, 8), (i) {
                    final p = _participants[i];
                    final speed = 12.0 + i * 3;
                    final phase = (i * 4.0) % speed;
                    final progress =
                        ((_floatController.value * speed + phase) % speed) / speed;
                    final xPos = constraints.maxWidth * (1.0 - progress) - 16;
                    final yVariation = [0.0, 4.0, -2.0][i % 3];
                    final opacity = progress < 0.05
                        ? progress / 0.05
                        : progress > 0.9
                            ? (1.0 - progress) / 0.1
                            : 1.0;

                    return Positioned(
                      left: xPos,
                      top: yVariation,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: _buildAvatar(p, size: 32),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(RoomParticipant p, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: ClipOval(
        child: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: p.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.hoverBg,
                  child: Icon(Icons.person,
                      color: AppColors.textPlaceholder, size: size * 0.5),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.hoverBg,
                  child: Icon(Icons.person,
                      color: AppColors.textPlaceholder, size: size * 0.5),
                ),
              )
            : Container(
                color: AppColors.hoverBg,
                child: Icon(Icons.person,
                    color: AppColors.textPlaceholder, size: size * 0.5),
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 歌词覆盖层
  // ══════════════════════════════════════════════════════════════

  Widget _buildLyricsOverlay() {
    final parsed = _getParsedLyrics();
    final activeIndex = parsed.isLrc ? _getActiveLyricIndex(parsed.lines) : -1;

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxHeight: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 曲名
              Text(
                _currentTrack?.name ?? '未知曲目',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // 歌词内容
              if (parsed.isLrc && parsed.lines.isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    controller: _lyricsScrollCtrl,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: List.generate(parsed.lines.length, (i) {
                        final line = parsed.lines[i];
                        final isActive = i == activeIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            line.text,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              fontSize: isActive ? 14 : 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
                    ),
                  ),
                )
              else if (parsed.rawText.isNotEmpty)
                Text(
                  parsed.rawText,
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 12,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  '暂无歌词',
                  style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
                ),
              const SizedBox(height: 4),
              // 关闭按钮
              GestureDetector(
                onTap: () => setState(() => _showLyrics = false),
                child: const Icon(Icons.close,
                    color: AppColors.textPlaceholder, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 底部操作栏
  // ══════════════════════════════════════════════════════════════

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 音频进度条（如果有曲目）
          if (_currentTrack != null) _buildAudioProgressBar(),
          // 迷你播放控制
          if (_audioTracks.isNotEmpty) _buildMiniPlayerControls(),
          // 轻语输入
          _buildSentenceInput(),
          const SizedBox(height: 8),
          // 退出房间
          GestureDetector(
            onTap: () {
              _leaveRoom();
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '退出房间',
                style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioProgressBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            _formatDuration(_currentPosition),
            style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: AppColors.auroraCyan,
                inactiveTrackColor: AppColors.borderDefault,
                thumbColor: AppColors.auroraCyan,
                overlayColor: AppColors.auroraCyan.withOpacity(0.2),
              ),
              child: Slider(
                value: _totalDuration.inMilliseconds > 0
                    ? _currentPosition.inMilliseconds
                        .toDouble()
                        .clamp(0, _totalDuration.inMilliseconds.toDouble())
                    : 0,
                max: _totalDuration.inMilliseconds > 0
                    ? _totalDuration.inMilliseconds.toDouble()
                    : 1,
                onChanged: (value) {
                  _seekTo(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_totalDuration),
            style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayerControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一首
          _buildPlayerIconButton(
            icon: Icons.skip_previous,
            onTap: _playPrevious,
            size: 28,
          ),
          const SizedBox(width: 16),
          // 播放/暂停
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.auroraGradientWithOpacity(0.6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgColor,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 下一首
          _buildPlayerIconButton(
            icon: Icons.skip_next,
            onTap: _playNext,
            size: 28,
          ),
          const SizedBox(width: 24),
          // 静音
          _buildPlayerIconButton(
            icon: _isMuted ? Icons.volume_off : Icons.volume_up,
            onTap: _toggleMute,
            size: 22,
            color: _isMuted ? AppColors.textWeak : AppColors.textPrimary,
          ),
          const SizedBox(width: 16),
          // 歌词开关
          _buildPlayerIconButton(
            icon: Icons.lyrics_outlined,
            onTap: () => setState(() => _showLyrics = !_showLyrics),
            size: 22,
            color: _showLyrics ? AppColors.auroraCyan : AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          // 播放模式
          _buildPlayerIconButton(
            icon: _getPlayModeIcon(),
            onTap: _cyclePlayMode,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 24,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color ?? AppColors.textSecondary, size: size),
    );
  }

  Widget _buildSentenceInput() {
    if (_showSentenceInput) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _sentenceCtrl.text.length >= 200
                      ? AppColors.auroraCyan
                      : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _sentenceCtrl,
                maxLength: 200,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '轻轻留下一句话...',
                  hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendSentence(),
                autofocus: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sentenceCtrl.text.trim().isNotEmpty ? _sendSentence : null,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: AppColors.auroraGradientWithOpacity(
                  _sentenceCtrl.text.trim().isNotEmpty ? 0.6 : 0.2,
                ),
              ),
              child: Center(
                child: Text(
                  '发送',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _showSentenceInput = false;
                _sentenceCtrl.clear();
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Icon(Icons.close, color: AppColors.textWeak, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showSentenceInput = true),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.hoverBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.auroraCyan, size: 16),
            const SizedBox(width: 8),
            Text(
              '轻语',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 声音设置面板
  // ══════════════════════════════════════════════════════════════

  Widget _buildSoundPanel() {
    if (_isSoundPanelMinimized) {
      return Positioned(
        left: _soundPanelPosition.dx,
        top: _soundPanelPosition.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _soundPanelPosition = Offset(
                (_soundPanelPosition.dx + details.delta.dx).clamp(
                  0, MediaQuery.of(context).size.width - 56),
                (_soundPanelPosition.dy + details.delta.dy).clamp(
                  0, MediaQuery.of(context).size.height - 56),
              );
            });
          },
          onTap: () => setState(() => _isSoundPanelMinimized = false),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.auroraGradientWithOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.auroraCyan.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                if (_isPlaying)
                  const SizedBox(height: 2)
                else
                  const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: _soundPanelPosition.dx,
      top: _soundPanelPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _soundPanelPosition = Offset(
              (_soundPanelPosition.dx + details.delta.dx).clamp(
                0, MediaQuery.of(context).size.width - _soundPanelWidth),
              (_soundPanelPosition.dy + details.delta.dy).clamp(
                0, MediaQuery.of(context).size.height - 100),
            );
          });
        },
        child: Container(
          width: _soundPanelWidth,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.overlayBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖动把手
                GestureDetector(
                  onTap: () => setState(() => _isSoundPanelMinimized = true),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textPlaceholder.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            '音乐控制',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _showSoundPanel = false),
                            child: const Icon(Icons.close,
                                color: AppColors.textPlaceholder, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 当前曲目信息
                if (_currentTrack != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.hoverBgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentTrack!.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SizedBox(
                                height: 2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1),
                                  child: LinearProgressIndicator(
                                    value: _totalDuration.inMilliseconds > 0
                                        ? _currentPosition.inMilliseconds /
                                            _totalDuration.inMilliseconds
                                        : 0,
                                    backgroundColor: AppColors.borderDefault,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.auroraCyan),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(_totalDuration),
                              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // 主控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 静音
                    _buildPanelControlButton(
                      icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                      onTap: _toggleMute,
                      isActive: _isMuted,
                    ),
                    const SizedBox(width: 12),
                    // 上一首
                    _buildPanelControlButton(
                      icon: Icons.skip_previous,
                      onTap: _playPrevious,
                    ),
                    const SizedBox(width: 12),
                    // 播放/暂停
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.auroraGradientWithOpacity(0.6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgColor,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 下一首
                    _buildPanelControlButton(
                      icon: Icons.skip_next,
                      onTap: _playNext,
                    ),
                    const SizedBox(width: 12),
                    // 播放模式
                    _buildPanelControlButton(
                      icon: _getPlayModeIcon(),
                      onTap: _cyclePlayMode,
                      tooltip: _getPlayModeLabel(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 音量控制
                Row(
                  children: [
                    Icon(Icons.volume_down, color: AppColors.textWeak, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          activeTrackColor: AppColors.auroraCyan,
                          inactiveTrackColor: AppColors.borderDefault,
                          thumbColor: AppColors.auroraCyan,
                          overlayColor: AppColors.auroraCyan.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _isMuted ? 0.0 : 0.5,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _isMuted = value == 0.0;
                            });
                            _audioPlayer.setVolume(value);
                          },
                        ),
                      ),
                    ),
                    Icon(Icons.volume_up, color: AppColors.textWeak, size: 16),
                  ],
                ),
                const SizedBox(height: 8),

                // 播放列表
                _buildPlaylist(),
                const SizedBox(height: 12),

                // 房主上传
                if (_isOwner) ...[
                  GestureDetector(
                    onTap: _uploadingAudio ? null : _uploadAudio,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload,
                              color: AppColors.textPrimary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _uploadingAudio
                                ? _uploadProgress.isNotEmpty
                                    ? _uploadProgress
                                    : '上传中...'
                                : '上传音频文件',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSoundPanel = false;
                        _showDisbandConfirm = true;
                      });
                    },
                    child: ShaderMask(
                      shaderCallback: (rect) =>
                          AppColors.auroraGradient.createShader(rect),
                      child: const Text(
                        '解散房间',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.auroraCyan.withOpacity(0.15) : AppColors.hoverBg,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.auroraCyan : AppColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildPanelRow({required String label, required Widget child}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const Spacer(),
        child,
      ],
    );
  }

  Widget _buildPlaylist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.queue_music, color: AppColors.textWeak, size: 14),
            const SizedBox(width: 4),
            Text(
              '播放列表',
              style: TextStyle(color: AppColors.textWeak, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${_audioTracks.length} 首',
              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_audioTracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '暂无音频，上传音频开始播放',
                style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _audioTracks.length,
              itemBuilder: (context, index) {
                final track = _audioTracks[index];
                final isCurrent = index == _currentTrackIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentTrackIndex = index);
                    if (!_isMuted) _playTrack(track.url);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isCurrent && _isPlaying
                          ? AppColors.bgColor
                          : AppColors.hoverBgLight,
                      border: isCurrent
                          ? Border.all(
                              color: AppColors.auroraCyan.withOpacity(0.5),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (track.duration != null)
                                Text(
                                  '${(track.duration! / 60).floor()}:${((track.duration! % 60).floor()).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: AppColors.textPlaceholder,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isOwner)
                          GestureDetector(
                            onTap: () => _deleteAudioTrack(track.id),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline,
                                  color: AppColors.textPlaceholder, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 解散确认对话框
  // ══════════════════════════════════════════════════════════════

  Widget _buildDisbandDialog() {
    return GestureDetector(
      onTap: () => setState(() => _showDisbandConfirm = false),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 阻止穿透
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.overlayBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.errorRed.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.power_settings_new,
                        color: AppColors.textPrimary, size: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '解散房间',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '确定要解散这个房间吗？\n此操作不可恢复，所有数据将被删除。',
                    style: TextStyle(color: AppColors.textWeak, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showDisbandConfirm = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppColors.hoverBg,
                            ),
                            child: const Center(
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _disbandRoom,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppColors.errorRed,
                            ),
                            child: const Center(
                              child: Text(
                                '确定解散',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 状态选择器
  // ══════════════════════════════════════════════════════════════

  Widget _buildStatusPicker() {
    return GestureDetector(
      onTap: () => setState(() => _showStatusPicker = false),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.overlayBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '当前状态',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statusOptions.map((s) {
                        final value = s['value'] as String;
                        final label = s['label'] as String;
                        final icon = s['icon'] as IconData;
                        final isSelected = _currentStatus == value;
                        return GestureDetector(
                          onTap: () {
                            _updateStatus(value);
                            setState(() => _showStatusPicker = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: isSelected
                                  ? AppColors.auroraCyan.withOpacity(0.2)
                                  : AppColors.hoverBg,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.auroraCyan
                                    : AppColors.borderDefault,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  color: isSelected
                                      ? AppColors.auroraCyan
                                      : AppColors.textSecondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.auroraCyan
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 成员列表 BottomSheet
  // ══════════════════════════════════════════════════════════════

  Widget _buildMembersSheet() {
    return GestureDetector(
      onTap: () => setState(() => _showMembersSheet = false),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.overlayBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          '房间成员 (${_participants.length})',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showMembersSheet = false),
                          child: const Icon(Icons.close,
                              color: AppColors.textPlaceholder, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _participants.length,
                        itemBuilder: (context, index) {
                          final p = _participants[index];
                          final statusLabel = _getStatusLabel(p.status);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.hoverBgLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildAvatar(p, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            p.username ?? '匿名',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (p.isOwner) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.star,
                                                color: AppColors.auroraYellow,
                                                size: 14),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: AppColors.textWeak,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 房主可以踢人（不能踢自己）
                                if (_isOwner && p.userId != _currentUserId)
                                  GestureDetector(
                                    onTap: () {
                                      _kickParticipant(p.userId);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        color: AppColors.errorRed
                                            .withOpacity(0.2),
                                      ),
                                      child: const Text(
                                        '移除',
                                        style: TextStyle(
                                          color: AppColors.errorRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
