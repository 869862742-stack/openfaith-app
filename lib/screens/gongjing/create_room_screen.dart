import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _descFocusNode = FocusNode();
  final List<String> _selectedTags = [];
  String? _musicFilePath;
  String? _musicTitle;
  bool _isPublic = true;
  bool _creating = false;
  String? _error;

  final List<String> _availableTags = [
    '\u51a5\u60f3', '\u97f3\u4e50', '\u7597\u6108', '\u8bfb\u4e66', '\u7948\u7977',
    '\u5b66\u4e60', '\u5de5\u4f5c', '\u8fd0\u52a8', '\u7f16\u7a0b', '\u5199\u4f5c',
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
    _descFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _nameFocusNode.dispose();
    _descFocusNode.dispose();
    super.dispose();
  }  static const _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),


    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.height, size.width) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = '\u8bf7\u8f93\u5165\u623f\u95f4\u540d\u79f0');
      return;
    }
    setState(() { _creating = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('\u672a\u767b\u5f55');

      String? musicUrl;
      if (_musicFilePath != null) {
        final ext = _musicFilePath!.split('.').last;
        final path = 'music/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Supabase.instance.client.storage.from('media').upload(path, File(_musicFilePath!));
        musicUrl = Supabase.instance.client.storage.from('media').getPublicUrl(path);
      }

      await Supabase.instance.client.from('rooms').insert({
        'owner_id': user.id,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'tags': _selectedTags,
        'is_public': _isPublic,
        'music_url': musicUrl,
        'music_title': _musicTitle,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _creating = false; });
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
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('\u521b\u5efa\u623f\u95f4', style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _creating ? null : _createRoom,
              child: LayoutBuilder(builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _diagonalGradient(size),
                ),
                child: _creating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('\u521b\u5efa', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              );
              }),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // \u623f\u95f4\u540d\u79f0
            LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Container(
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '\u623f\u95f4\u540d\u79f0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 16, fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onTapOutside: (event) => _nameFocusNode.unfocus(),
                ),
              ),
            );
            }),
            const SizedBox(height: 12),
            // \u63cf\u8ff0
            LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: _descFocusNode.hasFocus ? _diagonalGradient(size) : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: AppColors.inputBg,
                  border: _descFocusNode.hasFocus ? null : Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _descController,
                  focusNode: _descFocusNode,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '\u63cf\u8ff0\u4f60\u7684\u623f\u95f4...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onTapOutside: (event) => _descFocusNode.unfocus(),
                ),
              ),
            );
            }),
            const SizedBox(height: 16),
            // \u6807\u7b7e\u9009\u62e9
            const Text('\u623f\u95f4\u6807\u7b7e', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // \u97f3\u4e50\u4e0a\u4f20
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('\u97f3\u4e50\u4e0a\u4f20\u5f85\u96c6\u6210'), backgroundColor: AppColors.inputBg),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.inputBg,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.white.withOpacity(0.5), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _musicFilePath != null ? '\u5df2\u9009\u62e9\u97f3\u4e50' : '\u6dfb\u52a0\u80cc\u666f\u97f3\u4e50',
                            style: TextStyle(
                              color: _musicFilePath != null ? Colors.white : Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                          if (_musicTitle != null)
                            Text(_musicTitle!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.add, color: Colors.white.withOpacity(0.3), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // \u516c\u5f00/\u79c1\u5bc6
            GestureDetector(
              onTap: () => setState(() => _isPublic = !_isPublic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.inputBg,
                ),
                child: Row(
                  children: [
                    Icon(_isPublic ? Icons.public : Icons.lock_outline, color: Colors.white.withOpacity(0.5), size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_isPublic ? '\u516c\u5f00\u623f\u95f4' : '\u79c1\u5bc6\u623f\u95f4', style: const TextStyle(color: Colors.white, fontSize: 14))),
                    Switch(
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                      activeColor: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
