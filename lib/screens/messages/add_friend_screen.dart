import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _error;  static const _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),


    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.width, size.height) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() { _searching = true; _error = null; _results = []; });
    try {
      final client = Supabase.instance.client;
      // Search by email or username
      final resp = await client
          .from('profiles')
          .select('id, username, email, avatar_url')
          .or('username.ilike.%$query%,email.ilike.%$query%')
          .limit(20);
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        final filtered = (resp as List).where((u) => u['id'] != currentUser.id).toList();
        if (mounted) setState(() => _results = filtered.cast<Map<String, dynamic>>());
      } else {
        if (mounted) setState(() => _results = resp.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _sendFriendRequest(String userId, String username) async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      await client.from('friend_requests').insert({
        'from_user_id': currentUser.id,
        'to_user_id': userId,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u5df2\u5411 $username \u53d1\u9001\u597d\u53cb\u8bf7\u6c42'), backgroundColor: AppColors.inputBg),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u53d1\u9001\u5931\u8d25: $e'), backgroundColor: AppColors.inputBg),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('\u6dfb\u52a0\u597d\u53cb', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return Container(
                    height: 38,
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _searchFocusNode.hasFocus ? _diagonalGradient(size) : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: AppColors.inputBg,
                        border: _searchFocusNode.hasFocus ? null : Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '\u641c\u7d22\u7528\u6237\u540d\u6216\u90ae\u7bb1',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _search(),
                        onTapOutside: (event) => _searchFocusNode.unfocus(),
                      ),
                    ),
                  );
                  }),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _search,
                  child: LayoutBuilder(builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _diagonalGradient(size),
                    ),
                    child: Center(
                      child: _searching
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('\u641c\u7d22', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  );
                  }),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          // Results
          Expanded(
            child: _results.isEmpty && !_searching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 48, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text('\u641c\u7d22\u7528\u6237\u540d\u6216\u90ae\u7bb1\u6dfb\u52a0\u597d\u53cb', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Container(height: 1, color: Colors.white.withOpacity(0.04)),
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.inputBg,
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null
                                  ? Text((user['username'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 14))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['username'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  if (user['email'] != null)
                                    Text(user['email'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _sendFriendRequest(user['id'], user['username'] ?? 'user'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Text('\u6dfb\u52a0', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
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
    );
  }
}
