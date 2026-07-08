import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class PublishVideoScreen extends StatefulWidget {
  const PublishVideoScreen({super.key});

  @override
  State<PublishVideoScreen> createState() => _PublishVideoScreenState();
}

class _PublishVideoScreenState extends State<PublishVideoScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedVideoPath;
  String? _coverImagePath;
  bool _isPublic = true;
  bool _publishing = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static const _rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
      Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
    ],
  transform: GradientRotation(0.35),
  );

  Future<void> _publish() async {
    if (_selectedVideoPath == null) {
      setState(() => _error = '\u8bf7\u5148\u9009\u62e9\u89c6\u9891');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '\u8bf7\u8f93\u5165\u89c6\u9891\u6807\u9898');
      return;
    }
    setState(() { _publishing = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('\u672a\u767b\u5f55');

      // Upload video
      final videoExt = _selectedVideoPath!.split('.').last;
      final videoPath = 'videos/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$videoExt';
      await Supabase.instance.client.storage.from('media').upload(
        videoPath,
        // In real implementation, would use File(_selectedVideoPath!)
        // For now, placeholder for the upload logic
        File(_selectedVideoPath!),
      );

      final videoUrl = Supabase.instance.client.storage.from('media').getPublicUrl(videoPath);

      // Upload cover if exists
      String? coverUrl;
      if (_coverImagePath != null) {
        final coverExt = _coverImagePath!.split('.').last;
        final coverPath = 'covers/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$coverExt';
        await Supabase.instance.client.storage.from('media').upload(coverPath, File(_coverImagePath!));
        coverUrl = Supabase.instance.client.storage.from('media').getPublicUrl(coverPath);
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': _descriptionController.text.trim(),
        'title': _titleController.text.trim(),
        'visibility': _isPublic ? 'public' : 'private',
        'metadata': {
          'type': 'video',
          'video_url': videoUrl,
          'cover_url': coverUrl,
        },
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _publishing = false; });
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
        title: const Text('\u53d1\u5e03\u89c6\u9891', style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _publishing ? null : _publish,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _rainbowGradient,
                ),
                child: _publishing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('\u53d1\u5e03', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // \u89c6\u9891\u9009\u62e9
            GestureDetector(
              onTap: () {
                // In real implementation, would open file picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('\u89c6\u9891\u9009\u62e9\u5668\u5f85\u96c6\u6210'), backgroundColor: AppColors.inputBg),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.inputBg,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _selectedVideoPath != null
                    ? Stack(
                        children: [
                          Center(child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white.withOpacity(0.7))),
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedVideoPath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, size: 48, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text('\u70b9\u51fb\u9009\u62e9\u89c6\u9891', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // \u5c01\u9762\u9009\u62e9
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('\u5c01\u9762\u9009\u62e9\u5668\u5f85\u96c6\u6210'), backgroundColor: AppColors.inputBg),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.inputBg,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    _coverImagePath != null
                        ? Expanded(child: Icon(Icons.image, color: Colors.white.withOpacity(0.7)))
                        : Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 24, color: Colors.white.withOpacity(0.3)),
                                const SizedBox(width: 8),
                                Text('\u6dfb\u52a0\u5c01\u9762', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // \u6807\u9898
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '\u89c6\u9891\u6807\u9898',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 16, fontWeight: FontWeight.w600),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            // \u63cf\u8ff0
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '\u63cf\u8ff0\u4f60\u7684\u89c6\u9891...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    Expanded(child: Text(_isPublic ? '\u516c\u5f00\u89c6\u9891' : '\u79c1\u5bc6\u89c6\u9891', style: const TextStyle(color: Colors.white, fontSize: 14))),
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
