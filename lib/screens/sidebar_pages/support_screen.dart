import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';

/// 联系支持页 - 对齐网页版 Support.tsx
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _replyCtrl = TextEditingController();

  bool _submitting = false;
  bool _replying = false;
  bool _isVip = false;
  String _activeTab = 'my';
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic>? _selectedTicket;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTickets();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('profiles')
          .select('is_vip')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        if (!mounted) return;
        setState(() => _isVip = res['is_vip'] == true);
      }
    } catch (_) {}
  }

  Future<void> _loadTickets() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      if (res != null) {
        if (!mounted) return;
        setState(() {
          _tickets = List<Map<String, dynamic>>.from(res.map((t) {
            return {
              'id': t['id'],
              'title': t['subject'] ?? '',
              'content': t['description'] ?? '',
              'status': _mapStatus(t['status']),
              'date': t['created_at'] ?? '',
              'isVip': t['priority'] == 'vip',
              'adminReply': t['admin_reply'],
              'repliedAt': t['replied_at'],
            };
          }));
        });
      }
    } catch (e) {
      debugPrint('Load tickets error: $e');
    }
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'open':
        return 'pending';
      case 'in_progress':
        return 'processing';
      case 'resolved':
        return 'resolved';
      default:
        return 'pending';
    }
  }

  Future<void> _submitTicket() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      _showSnackBar('请填写标题和内容');
      return;
    }
    setState(() => _submitting = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _showSnackBar('请先登录');
        return;
      }
      await _supabase.from('support_tickets').insert({
        'user_id': userId,
        'subject': _titleCtrl.text.trim(),
        'description': _contentCtrl.text.trim(),
        'status': 'open',
        'priority': _isVip ? 'vip' : 'normal',
      });
      _titleCtrl.clear();
      _contentCtrl.clear();
      _showSnackBar('提交成功，我们会尽快回复');
      await _loadTickets();
      if (!mounted) return;
      setState(() => _activeTab = 'my');
    } catch (e) {
      _showSnackBar('提交失败: $e');
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  Future<void> _replyToTicket() async {
    if (_replyCtrl.text.trim().isEmpty || _selectedTicket == null) return;
    setState(() => _replying = true);
    try {
      final ticketId = _selectedTicket!['id'];
      final oldContent = _selectedTicket!['content'] ?? '';
      final now = DateTime.now().toIso8601String();
      final newContent =
          '$oldContent\n\n--- 用户补充（${_formatDate(now)}）---\n${_replyCtrl.text.trim()}';
      await _supabase
          .from('support_tickets')
          .update({'description': newContent, 'status': 'open'}).eq('id', ticketId);
      _replyCtrl.clear();
      await _loadTickets();
      // Update selected ticket content
      final updated = _tickets.firstWhere(
        (t) => t['id'] == ticketId,
        orElse: () => {},
      );
      if (updated.isNotEmpty) {
        if (!mounted) return;
        setState(() => _selectedTicket = updated);
      }
      _showSnackBar('回复成功，我们会尽快处理');
    } catch (e) {
      _showSnackBar('回复失败: $e');
    } finally {
      if (!mounted) return;
      setState(() => _replying = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.overlayBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return '待处理';
      case 'processing':
        return '处理中';
      case 'resolved':
        return '已解决';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.auroraOrange;
      case 'processing':
        return AppColors.auroraCyan;
      case 'resolved':
        return AppColors.auroraGreen;
      default:
        return AppColors.textWeak;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _openTicketDetail(Map<String, dynamic> ticket) {
    setState(() {
      _selectedTicket = ticket;
      _replyCtrl.clear();
    });
    _showTicketDetailDialog(ticket);
  }

  void _showTicketDetailDialog(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderDefault,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.borderDefault,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '工单详情',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatusBadge(ticket),
                            if (ticket['isVip'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.auroraOrange
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: AppColors.auroraOrange,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'VIP',
                                      style: TextStyle(
                                        color: AppColors.auroraOrange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & date
                              Text(
                                ticket['title']?.toString() ?? '',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '提交时间：${_formatDate(ticket['date'])}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // User message bubble
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(ctx).size.width * 0.8,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16)
                                        .copyWith(
                                      topRight: const Radius.circular(4),
                                    ),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.auroraBlue,
                                        AppColors.auroraPurple,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket['content']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(ticket['date']),
                                        style: TextStyle(
                                          color: AppColors.textPrimary
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Admin reply
                              if (ticket['adminReply'] != null &&
                                  (ticket['adminReply'] as String)
                                      .toString()
                                      .isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(ctx).size.width * 0.8,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.hoverBg,
                                      borderRadius: BorderRadius.circular(16)
                                          .copyWith(
                                        topLeft: const Radius.circular(4),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: AppColors.auroraCyan,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.bolt,
                                                color: AppColors.bgColor,
                                                size: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '客服',
                                              style: TextStyle(
                                                color: AppColors.auroraCyan,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ticket['adminReply'].toString(),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (ticket['repliedAt'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(ticket['repliedAt']),
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                              // No reply hint
                              if (ticket['adminReply'] == null ||
                                  (ticket['adminReply'] as String)
                                      .toString()
                                      .isEmpty) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: AppColors.textPlaceholder,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '等待客服处理中...',
                                        style: TextStyle(
                                          color: AppColors.textWeak,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Reply area
                      if (ticket['status'] != 'resolved')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.borderDefault,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '补充内容',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _replyCtrl,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: '请输入需要补充的内容...',
                                  hintStyle: TextStyle(
                                    color: AppColors.textPlaceholder,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.hoverBg,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderDefault,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderDefault,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderActive,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        '取消',
                                        style: TextStyle(
                                          color: AppColors.textWeak,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _replying
                                        ? null
                                        : () {
                                            _replyToTicket();
                                          },
                                    child: RainbowBorder(
                                      borderRadius: 12,
                                      borderWidth: 1.5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: _replying
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.textPrimary,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.send,
                                                color: AppColors.textPrimary,
                                                size: 16,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // Resolved hint
                      if (ticket['status'] == 'resolved')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.borderDefault,
                                width: 0.5,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '✓ 此工单已处理完成',
                            style: TextStyle(
                              color: AppColors.auroraGreen,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'pending';
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 毛玻璃 Header ──
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderDefault,
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '欢迎联系',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Tab 切换 ──
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderDefault,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('my', '我的工单'),
                const SizedBox(width: 16),
                _buildTabButton('new', '新建工单'),
              ],
            ),
          ),

          // ── 内容区域 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // VIP 优先客服提示
                  if (_isVip) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.hoverBg,
                            AppColors.hoverBgLight,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: AppColors.textPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '会员优先客服',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '您的工单将进入优先队列',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── 我的工单 Tab ──
                  if (_activeTab == 'my') ...[
                    if (_tickets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppColors.textWeak,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无工单记录',
                              style: TextStyle(
                                color: AppColors.textWeak,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '如果您在使用过程中遇到问题，请点击"新建工单"反馈',
                              style: TextStyle(
                                color: AppColors.textWeak,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._tickets.map((ticket) => _buildTicketCard(ticket)),
                  ],

                  // ── 新建工单 Tab ──
                  if (_activeTab == 'new') ...[
                    const SizedBox(height: 32),
                    // 标题
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '问题标题',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '请简要描述您的问题',
                        hintStyle: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.hoverBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderDefault,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderDefault,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderActive,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 详情
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '问题详情',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '请详细描述您遇到的问题，以便我们更好地帮助您...',
                        hintStyle: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.hoverBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderDefault,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderDefault,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderActive,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 提交按钮
                    _buildSubmitButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isActive = _activeTab == tab;
    if (isActive) {
      return RainbowBorder(
        borderRadius: 20,
        borderWidth: 1.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            color: AppColors.cardBg,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'pending';
    final isVip = ticket['isVip'] == true;
    final hasReply = ticket['adminReply'] != null &&
        (ticket['adminReply'] as String).toString().isNotEmpty;

    return GestureDetector(
      onTap: () => _openTicketDetail(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVip ? AppColors.borderActive : AppColors.borderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket['title']?.toString() ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVip) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.workspace_premium,
                    color: AppColors.auroraOrange,
                    size: 12,
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  _statusText(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textPlaceholder,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket['content']?.toString() ?? '',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(ticket['date']),
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    if (hasReply) ...[
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.auroraCyan,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '有回复',
                        style: TextStyle(
                          color: AppColors.auroraCyan,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _titleCtrl.text.trim().isNotEmpty &&
        _contentCtrl.text.trim().isNotEmpty &&
        !_submitting;

    return GestureDetector(
      onTap: canSubmit ? _submitTicket : null,
      child: RainbowBorder(
        borderRadius: 12,
        borderWidth: 1.5,
        opacity: canSubmit ? 0.8 : 0.3,
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.send,
                color: canSubmit ? AppColors.textPrimary : AppColors.textPlaceholder,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _submitting ? '提交中...' : '提交反馈',
                style: TextStyle(
                  color: canSubmit
                      ? AppColors.textPrimary
                      : AppColors.textPlaceholder,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
