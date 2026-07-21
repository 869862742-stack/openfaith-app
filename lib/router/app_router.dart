import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../webview/webview_shell.dart';
import '../navigation/bottom_nav.dart';
import '../screens/book_library_screen.dart';
import '../screens/religion_book_list_screen.dart';
import '../screens/book_reader_screen.dart';
import '../screens/call/call_screen.dart';

/// 路由配置 — WebView 为主 + 藏书原生模块
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 主页 = WebView 加载网页版
    GoRoute(
      path: '/home',
      builder: (context, state) => const BottomNavScreen(),
    ),
    // 通话页面
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CallScreen(
          myUserId: extra['myUserId'] as String? ?? '',
          peerUserId: extra['peerUserId'] as String? ?? '',
          peerName: extra['peerName'] as String? ?? '',
          callType: extra['callType'] as String? ?? 'voice',
          isIncoming: extra['isIncoming'] as bool? ?? false,
          callId: extra['callId'] as String?,
          channelName: extra['channelName'] as String?,
          onCallEnd: extra['onCallEnd'] as VoidCallback?,
        );
      },
    ),
    // 藏书阁（原生，宗教分类列表）
    GoRoute(
      path: '/books',
      builder: (context, state) => const BookLibraryScreen(),
    ),
    // 宗教藏书列表
    GoRoute(
      path: '/books/religion/:religionId',
      builder: (context, state) {
        final religionId = state.pathParameters['religionId']!;
        final religionName = state.uri.queryParameters['name'] ?? '';
        return ReligionBookListScreen(
          religionId: religionId,
          religionName: religionName,
        );
      },
    ),
    // 书籍阅读器
    GoRoute(
      path: '/books/:bookId',
      builder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        final title = state.uri.queryParameters['title'] ?? '藏书';
        final fileUrl = state.uri.queryParameters['fileUrl'] ?? '';
        return BookReaderScreen(
          bookId: bookId,
          title: title,
          fileUrl: fileUrl,
        );
      },
    ),
  ],
);
