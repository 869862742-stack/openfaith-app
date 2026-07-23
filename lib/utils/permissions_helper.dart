import 'package:permission_handler/permission_handler.dart';

/// 通话权限管理工具类
class PermissionsHelper {
  PermissionsHelper._();

  /// 请求通话所需权限
  /// [needCamera] 是否需要摄像头（视频通话）
  /// 返回是否获得所有必要权限
  static Future<bool> requestCallPermissions({required bool needCamera}) async {
    // 请求麦克风权限（必须）
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      return false;
    }

    // 视频通话需要摄像头（必须）
    if (needCamera) {
      final camStatus = await Permission.camera.request();
      if (camStatus.isDenied || camStatus.isPermanentlyDenied) {
        return false;
      }
    }

    // Android 13+ 需要通知权限（非必须，不阻止通话）
    try {
      await Permission.notification.request();
    } catch (e) {
      // 通知权限不是必须的
    }

    return true;
  }

  /// 检查是否已有通话权限（不触发请求弹窗）
  static Future<bool> hasCallPermissions({required bool needCamera}) async {
    final micGranted = await Permission.microphone.isGranted;
    if (!micGranted) return false;

    if (needCamera) {
      final camGranted = await Permission.camera.isGranted;
      if (!camGranted) return false;
    }

    return true;
  }

  /// 打开系统设置页面（用于引导用户手动开启权限）
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
