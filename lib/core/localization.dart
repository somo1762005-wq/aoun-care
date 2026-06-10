class AppLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      // Welcome Screen
      'welcome_title': 'مرحبًا بك في عوْن',
      'welcome_subtitle': 'معك في كل لحظة اهتمام',
      'welcome_desc': 'ابدأ رحلة العناية الذكية بكبير العائلة. تذكيرات، متابعة، وطمأنينة في مكان واحد🚀',
      'start_now': 'ابدأ الآن',
      
      // Auth Screen
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'phone_number': 'رقم هاتف الابن (للطوارئ)',
      'phone_validation_error': 'الرجاء إدخال رقم هاتف صحيح',
      'email_validation_error': 'الرجاء إدخال بريد إلكتروني صحيح',
      'password_validation_error': 'كلمة المرور يجب أن لا تقل عن 8 أحرف',
      'field_required': 'هذا الحقل مطلوب',
      'have_account': 'لديك حساب بالفعل؟ سجل دخولك',
      'dont_have_account': 'ليس لديك حساب؟ أنشئ حسابًا الآن',
      
      // Role Selection
      'role_selection_title': 'شاشة اختيار الواجهة',
      'role_selection_subtitle': 'اختر طبيعة استخدامك لهذا الجهاز',
      'role_caregiver': 'واجهة الابن (مقدم الرعاية)',
      'role_elderly': 'واجهة الأب (متلقي الرعاية)',
      
      // Father Interface
      'father_title': 'واجهة الأب',
      'next_dose_in': 'متبقي على الجرعة القادمة',
      'minutes': 'دقائق',
      'seconds': 'ثواني',
      'no_upcoming_doses': 'لا توجد جرعات قادمة اليوم',
      'alarm_title': '‼️ حان وقت جرعة الدواء',
      'mark_as_taken': 'تم أخذ الجرعة',
      'escalation_warning': 'تنبيه: سيتم إرسال إشعار للابن في حال عدم التأكيد',
      'taken_success': 'تم تسجيل أخذ الجرعة بنجاح',
      
      // Son Interface
      'son_title': 'واجهة الابن',
      'tab_medication': 'الأدوية',
      'tab_reports': 'التقارير',
      'tab_map': 'الموقع',
      'tab_settings': 'الإعدادات',
      
      // Tab 1: Medication
      'medication_list': 'قائمة الأدوية النشطة',
      'add_medicine': 'إضافة دواء جديد',
      'edit_medicine': 'تعديل الدواء',
      'medicine_name': 'اسم الدواء',
      'dose_times': 'أوقات الجرعات اليومية',
      'add_time': 'إضافة وقت',
      'initial_stock': 'الكمية الإجمالية المتبقية',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'stock_warning': 'تحذير: الكمية من دواء {name} أوشكت على النفاذ!',
      'remaining_doses': 'الجرعات المتبقية: {count}',
      
      // Tab 2: Reports
      'weekly_reports': 'التقارير والأنشطة الأسبوعية',
      'taken_log': 'تم أخذ الجرعة [{name}] في الموعد [{time}] بنجاح',
      'missed_log': 'لم يتم أخذ الجرعة [{name}] في الموعد [{time}]',
      'no_activity': 'لا توجد أنشطة مسجلة بعد',
      
      // Tab 3: Live Map
      'live_tracking': 'التتبع المباشر للأب',
      'father_coordinates': 'إحداثيات الموقع الحالية للأب',
      'track_now': 'تحديث الموقع الآن',
      'lat': 'خط العرض',
      'lng': 'خط الطول',
      
      // Tab 4: Settings
      'settings': 'الإعدادات',
      'about_app': 'حول التطبيق',
      'about_desc': 'تطبيق عوْن هو نظام ذكي لتتبع الأدوية والرعاية الصحية يربط بين الأب (كبير السن) والابن (مقدم الرعاية) بشكل متزامن. يهدف التطبيق إلى الحفاظ على سلامة الوالدين من خلال التذكيرات التلقائية وتتبع المخزون ونظام التصعيد الذكي في حالات الطوارئ.',
      'language_settings': 'إعدادات اللغة',
      'share_app': 'شارك التطبيق',
      'share_text': 'أنصحك باستخدام تطبيق عوْن لرعاية وتتبع أدوية والديك بكل سهولة وطمأنينة.',
      'escalation_settings': 'إعدادات المهلة والتصعيد',
      'escalation_buffer_father': 'مهلة تأكيد الأب (بالدقائق)',
      'escalation_buffer_son': 'مهلة تنبيه الابن قبل إرسال الرسالة النصية (بالدقائق)',
      'logout': 'تسجيل الخروج',
      
      // Global
      'theme_mode': 'وضع المظهر',
      'language': 'اللغة',
    },
    'en': {
      // Welcome Screen
      'welcome_title': 'Welcome to Aoun Care',
      'welcome_subtitle': 'With you in every moment of care',
      'welcome_desc': 'Begin the journey of smart care for the elder of the family. Reminders, tracking, and peace of mind in one place🚀',
      'start_now': 'Start Now',
      
      // Auth Screen
      'login': 'Login',
      'register': 'Sign Up',
      'email': 'Email Address',
      'password': 'Password',
      'phone_number': 'Son\'s Phone Number (Emergency)',
      'phone_validation_error': 'Please enter a valid phone number',
      'email_validation_error': 'Please enter a valid email address',
      'password_validation_error': 'Password must be at least 8 characters',
      'field_required': 'This field is required',
      'have_account': 'Already have an account? Login',
      'dont_have_account': 'Don\'t have an account? Sign up now',
      
      // Role Selection
      'role_selection_title': 'Role Selection',
      'role_selection_subtitle': 'Choose how you will use this device',
      'role_caregiver': 'Son\'s Interface (Caregiver Mode)',
      'role_elderly': 'Father\'s Interface (Elderly Mode)',
      
      // Father Interface
      'father_title': 'Father\'s Dashboard',
      'next_dose_in': 'Time remaining for next dose',
      'minutes': 'min',
      'seconds': 'sec',
      'no_upcoming_doses': 'No upcoming doses today',
      'alarm_title': '‼️ Time for medication dose',
      'mark_as_taken': 'Dose Taken',
      'escalation_warning': 'Warning: Caregiver will be notified if not confirmed',
      'taken_success': 'Dose recorded successfully',
      
      // Son Interface
      'son_title': 'Son\'s Dashboard',
      'tab_medication': 'Medications',
      'tab_reports': 'Reports',
      'tab_map': 'Location',
      'tab_settings': 'Settings',
      
      // Tab 1: Medication
      'medication_list': 'Active Medications',
      'add_medicine': 'Add New Medicine',
      'edit_medicine': 'Edit Medicine',
      'medicine_name': 'Medicine Name',
      'dose_times': 'Daily Dose Times',
      'add_time': 'Add Time',
      'initial_stock': 'Total Remaining Quantity',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'stock_warning': 'Warning: Stock for {name} is running low!',
      'remaining_doses': 'Remaining doses: {count}',
      
      // Tab 2: Reports
      'weekly_reports': 'Weekly Reports & Activities',
      'taken_log': 'Dose [{name}] at [{time}] was taken successfully',
      'missed_log': 'Dose [{name}] at [{time}] was missed',
      'no_activity': 'No activities recorded yet',
      
      // Tab 3: Live Map
      'live_tracking': 'Live Father Tracking',
      'father_coordinates': 'Father\'s Current Coordinates',
      'track_now': 'Track Location Now',
      'lat': 'Latitude',
      'lng': 'Longitude',
      
      // Tab 4: Settings
      'settings': 'Settings',
      'about_app': 'About App',
      'about_desc': 'Aoun Care is a smart medication tracking and health care synchronization system connecting the father (elderly) and the son (caregiver). It aims to keep parents safe via automated alerts, inventory tracking, and escalation policies.',
      'language_settings': 'Language Settings',
      'share_app': 'Share App',
      'share_text': 'I highly recommend using Aoun Care to track your parents\' medication and care easily and with peace of mind.',
      'escalation_settings': 'Escalation & Safety Buffers',
      'escalation_buffer_father': 'Father Confirm Buffer (min)',
      'escalation_buffer_son': 'Son Warning Buffer before SMS (min)',
      'logout': 'Logout',
      
      // Global
      'theme_mode': 'Theme Mode',
      'language': 'Language',
    }
  };

  static String translate(String key, String langCode, {Map<String, String>? arguments}) {
    String value = _localizedValues[langCode]?[key] ?? key;
    if (arguments != null) {
      arguments.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }
}
