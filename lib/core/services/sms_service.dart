import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  // اسم القناة المتطابق تماماً مع كود مانوس بداخل الـ MainActivity
  static const MethodChannel _smsChannel = MethodChannel('com.aoun.app/sms');

  /// دالة إرسال الرسالة النصية في الخلفية دون تدخل المستخدم
  static Future<void> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // 1. طلب صلاحية إرسال الـ SMS في وقت التشغيل (مهمة جداً للأندرويد الحديث)
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }

      // 2. إذا وافق المستخدم (الوالد) عند تشغيل التطبيق أول مرة، يتم الإرسال فوراً
      if (status.isGranted) {
        final String result = await _smsChannel.invokeMethod('sendSMS', {
          'phone': phoneNumber.trim(),
          'message': message,
        });
        debugPrint("Native SMS Success: $result");
      } else {
        debugPrint("SMS Permission denied. Cannot send direct SMS.");
      }
    } catch (e) {
      debugPrint("Error calling Native SMS Channel: $e");
    }
  }
}