import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceId {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return 'WEB_${webInfo.userAgent?.hashCode ?? 'unknown'}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'ANDROID_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'IOS_${iosInfo.identifierForVendor ?? 'unknown'}';
      } else {
        return 'DESKTOP_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      return 'UNKNOWN_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
