import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _searchFocusNode = FocusNode();
  final List<Map<String, dynamic>> _allFriends = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _nameFocusNode.addListener(() => setState(() {}));
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _nameFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    // In real implementation, load from Supabase
    // For now, placeholder
    setState(() => _loading = false);
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u8bf7\u8f93\u5165\u7fa4\u804a\u540d\u79f0'), backgroundColor: AppColors.inputBg),
      );
      return;
    }
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u8bf7\u81f3\u5c11\u9009\u62e92\u4f4d\u597d\u53cb'), backgroundColor: AppColors.inputBg),
      );
      return;
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Create group chat
      final groupResp = await client.from('group_chats').insert({
        'name': _nameController.text.trim(),
        'owner_id': user.id,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select();

      if (groupResp.isNotEmpty) {
        final groupId = groupResp[0]['id'];
        // Add selected members
        final memberIds = [user.id, ..._selectedIds];
        for (final memberId in memberIds) {
          await client.from('group_chat_members').insert({
            'group_id': groupId,
            'user_id': memberId,
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u521b\u5efa\u5931\u8d25: $e'), backgroundColor: AppColors.inputBg),
        );
      }
    }
  }  static const _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),


    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.height, size.width) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('\u521b\u5efa\u7fa4\u804a', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Group name input
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Container(
              height: 40,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: _nameFocusNode.hasFocus ? _diagonalGradient(size) : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: AppColors.inputBg,
                  border: _nameFocusNode.hasFocus ? null : Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '\u8f93\u5165\u7fa4\u804a\u540d\u79f0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  onTapOutside: (event) => _nameFocusNode.unfocus(),
                ),
              ),
            );
            }),
          ),
          // Selected count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('\u5df2\u9009 ${ _selectedIds.length} \u4eba',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                const Spacer(),
                GestureDetector(
                  onTap: _createGroup,
                  child: LayoutBuilder(builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: _diagonalGradient(size),
                    ),
                    child: const Text('\u521b\u5efa', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Container(
              height: 36,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: _searchFocusNode.hasFocus ? _diagonalGradient(size) : null,
                color: _searchFocusNode.hasFocus ? null : AppColors.inputBg,
                border: _searchFocusNode.hasFocus ? null : Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: _searchFocusNode.hasFocus ? const Color(0xFF050816) : AppColors.inputBg,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '\u641c\u7d22\u597d\u53cb',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    prefixIcon: Icon(Icons.search, color: Colors.white38, size: 18),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  onTapOutside: (event) => _searchFocusNode.unfocus(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            );
            }),
          ),
          const SizedBox(height: 8),
          // Friends list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                : _allFriends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_add, size: 48, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text('\u6682\u65e0\u597d\u53cb\uff0c\u5148\u6dfb\u52a0\u597d\u53cb\u5427', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _allFriends.where((f) {
                          if (_searchController.text.isEmpty) return true;
                          return (f['username'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
                        }).length,
                        itemBuilder: (context, index) {
                          final friend = _allFriends.where((f) {
                            if (_searchController.text.isEmpty) return true;
                            return (f['username'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
                          }).elementAt(index);
                          final id = friend['id'] as String;
                          final isSelected = _selectedIds.contains(id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) { _selectedIds.remove(id); } else { _selectedIds.add(id); }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    width: 20, height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                      color: isSelected ? const Color(0xFF3A86FF) : Colors.transparent,
                                    ),
                                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.inputBg,
                                    backgroundImage: friend['avatar_url'] != null ? NetworkImage(friend['avatar_url']) : null,
                                    child: friend['avatar_url'] == null
                                        ? Text((friend['username'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 13))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(friend['username'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ],
                              ),
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
