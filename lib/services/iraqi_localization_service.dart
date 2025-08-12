import 'dart:ui';

class IraqiLocalizationService {
  static const Map<String, Map<String, String>> translations = {
    'ar': {
      // Common phrases
      'hello': 'مرحبا',
      'welcome': 'أهلاً وسهلاً',
      'thank_you': 'شكراً',
      'please': 'من فضلك',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'حسناً',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'loading': 'جاري التحميل...',

      // Driver app specific
      'driver_app': 'تطبيق السائق حاضر',
      'available_orders': 'الطلبات المتاحة',
      'accept_order': 'قبول الطلب',
      'reject_order': 'رفض الطلب',
      'pickup_location': 'موقع الاستلام',
      'delivery_location': 'موقع التسليم',
      'customer_name': 'اسم الزبون',
      'order_value': 'قيمة الطلب',
      'delivery_fee': 'أجرة التوصيل',
      'distance': 'المسافة',
      'estimated_time': 'الوقت المتوقع',

      // Order statuses
      'order_pending': 'في انتظار السائق',
      'order_accepted': 'تم قبول الطلب',
      'order_picked_up': 'تم استلام الطلب',
      'order_on_way': 'في الطريق للتسليم',
      'order_delivered': 'تم التسليم',
      'order_cancelled': 'ملغي',

      // Navigation
      'home': 'الرئيسية',
      'orders': 'الطلبات',
      'earnings': 'الأرباح',
      'schedule': 'الجدول',
      'profile': 'الملف الشخصي',
      'more': 'المزيد',

      // Authentication & Registration
      'register_new_account': 'تسجيل حساب جديد',
      'full_name': 'الاسم الكامل',
      'phone_number': 'رقم الهاتف',
      'password': 'كلمة المرور',
      'id_number': 'رقم الهوية',
      'vehicle_type': 'نوع المركبة',
      'vehicle_plate': 'رقم لوحة المركبة',
      'driving_license': 'رقم رخصة القيادة',
      'please_enter_full_name': 'يرجى إدخال الاسم الكامل',
      'please_enter_phone': 'يرجى إدخال رقم الهاتف',
      'please_enter_password': 'يرجى إدخال كلمة المرور',
      'please_enter_id': 'يرجى إدخال رقم الهوية',
      'please_enter_vehicle_type': 'يرجى إدخال نوع المركبة',
      'please_enter_vehicle_plate': 'يرجى إدخال رقم لوحة المركبة',
      'please_enter_license': 'يرجى إدخال رقم رخصة القيادة',
      'password_min_8_chars': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
      'register_with_cognito': 'تسجيل مع AWS Cognito',
      'already_have_account': 'لديك حساب؟ ',
      'login': 'سجل دخولك',
      'registration_failed': 'فشل في التسجيل. حاول مرة أخرى.',
      'registration_error': 'خطأ في التسجيل',
      'arabic_language': 'العربية',
      'kurdish_language': 'الكردية',
      'english_language': 'الإنجليزية',

      // Earnings
      'daily_earnings': 'الأرباح اليومية',
      'weekly_earnings': 'الأرباح الأسبوعية',
      'monthly_earnings': 'الأرباح الشهرية',
      'total_orders': 'إجمالي الطلبات',
      'completed_orders': 'الطلبات المكتملة',
      'commission': 'العمولة',
      'bonus': 'المكافأة',

      // Iraqi specific terms
      'iraqi_dinar': 'دينار عراقي',
      'dinar_short': 'د.ع',
      'zain_cash': 'زين كاش',
      'asia_cell_pay': 'آسيا سيل باي',
      'cash_on_delivery': 'الدفع عند الاستلام',

      // Cities
      'baghdad': 'بغداد',
      'basra': 'البصرة',
      'erbil': 'أربيل',
      'mosul': 'الموصل',
      'najaf': 'النجف',
      'karbala': 'كربلاء',
      'tikrit': 'تكريت',
      'ramadi': 'الرمادي',
      'fallujah': 'الفلوجة',
      'duhok': 'دهوك',
      'sulaymaniyah': 'السليمانية',
      'kirkuk': 'كركوك',

      // Common Iraqi expressions
      'inshallah': 'إن شاء الله',
      'habibi': 'حبيبي',
      'yalla': 'يلا',
      'khalas': 'خلاص',
      'shukran_jazeelan': 'شكراً جزيلاً',
      'allah_ma3aki': 'الله معاكِ',
      'allah_ma3ak': 'الله معاك',
    },

    'ku': {
      // Common phrases in Kurdish (Sorani)
      'hello': 'سڵاو',
      'welcome': 'بەخێربێیت',
      'thank_you': 'سوپاس',
      'please': 'تکایە',
      'yes': 'بەڵێ',
      'no': 'نەخێر',
      'ok': 'باشە',
      'cancel': 'هەڵوەشاندنەوە',
      'confirm': 'پشتڕاستکردنەوە',
      'loading': 'بارکردن...',

      // Driver app specific
      'driver_app': 'ئەپی شۆفێری حاضر',
      'available_orders': 'داواکارییە بەردەستەکان',
      'accept_order': 'قبووڵکردنی داواکاری',
      'pickup_location': 'شوێنی وەرگرتن',
      'delivery_location': 'شوێنی گەیاندن',
      'customer_name': 'ناوی کڕیار',
      'order_value': 'نرخی داواکاری',
      'delivery_fee': 'کرێی گەیاندن',

      // Cities in Kurdish
      'erbil': 'هەولێر',
      'duhok': 'دهۆک',
      'sulaymaniyah': 'سلێمانی',
      'kirkuk': 'کەرکووک',
      'zakho': 'زاخۆ',

      // Navigation
      'home': 'ماڵەوە',
      'orders': 'داواکارییەکان',
      'earnings': 'قازانج',
      'profile': 'پرۆفایل',

      // Authentication & Registration
      'register_new_account': 'خۆتۆمارکردنی هەژماری نوێ',
      'full_name': 'ناوی تەواو',
      'phone_number': 'ژمارەی تەلەفۆن',
      'password': 'وشەی نهێنی',
      'id_number': 'ژمارەی ناسنامە',
      'vehicle_type': 'جۆری ئۆتۆمبێل',
      'vehicle_plate': 'ژمارەی پلێتی ئۆتۆمبێل',
      'driving_license': 'ژمارەی مۆڵەتی لێخوڕین',
      'please_enter_full_name': 'تکایە ناوی تەواو بنووسە',
      'please_enter_phone': 'تکایە ژمارەی تەلەفۆن بنووسە',
      'please_enter_password': 'تکایە وشەی نهێنی بنووسە',
      'please_enter_id': 'تکایە ژمارەی ناسنامە بنووسە',
      'please_enter_vehicle_type': 'تکایە جۆری ئۆتۆمبێل بنووسە',
      'please_enter_vehicle_plate': 'تکایە ژمارەی پلێتی ئۆتۆمبێل بنووسە',
      'please_enter_license': 'تکایە ژمارەی مۆڵەتی لێخوڕین بنووسە',
      'password_min_8_chars': 'وشەی نهێنی دەبێت لانیکەم ٨ پیت بێت',
      'register_with_cognito': 'خۆتۆمارکردن لەگەڵ AWS Cognito',
      'already_have_account': 'هەژمارت هەیە؟ ',
      'login': 'چوونەژوورەوە',
      'registration_failed': 'خۆتۆمارکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدەوە.',
      'registration_error': 'هەڵەی خۆتۆمارکردن',
      'arabic_language': 'عەرەبی',
      'kurdish_language': 'کوردی',
      'english_language': 'ئینگلیزی',
    },

    'en': {
      // English fallback
      'hello': 'Hello',
      'welcome': 'Welcome',
      'thank_you': 'Thank you',
      'please': 'Please',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'loading': 'Loading...',

      'driver_app': 'Hadhir Driver',
      'available_orders': 'Available Orders',
      'accept_order': 'Accept Order',
      'pickup_location': 'Pickup Location',
      'delivery_location': 'Delivery Location',
      'customer_name': 'Customer Name',
      'order_value': 'Order Value',
      'delivery_fee': 'Delivery Fee',

      'home': 'Home',
      'orders': 'Orders',
      'earnings': 'Earnings',
      'profile': 'Profile',

      // Authentication & Registration
      'register_new_account': 'Register New Account',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'password': 'Password',
      'id_number': 'ID Number',
      'vehicle_type': 'Vehicle Type',
      'vehicle_plate': 'Vehicle Plate',
      'driving_license': 'Driving License',
      'please_enter_full_name': 'Please enter full name',
      'please_enter_phone': 'Please enter phone number',
      'please_enter_password': 'Please enter password',
      'please_enter_id': 'Please enter ID number',
      'please_enter_vehicle_type': 'Please enter vehicle type',
      'please_enter_vehicle_plate': 'Please enter vehicle plate',
      'please_enter_license': 'Please enter driving license',
      'password_min_8_chars': 'Password must be at least 8 characters',
      'register_with_cognito': 'Register with AWS Cognito',
      'already_have_account': 'Already have an account? ',
      'login': 'Login',
      'registration_failed': 'Registration failed. Please try again.',
      'registration_error': 'Registration error',
      'arabic_language': 'Arabic',
      'kurdish_language': 'Kurdish',
      'english_language': 'English',
    },
  };

  static String _currentLanguage = 'ar'; // Default to Arabic

  static void setLanguage(String languageCode) {
    if (translations.containsKey(languageCode)) {
      _currentLanguage = languageCode;
    }
  }

  static String translate(String key) {
    final languageMap = translations[_currentLanguage];
    if (languageMap != null && languageMap.containsKey(key)) {
      return languageMap[key]!;
    }

    // Fallback to English
    final englishMap = translations['en'];
    if (englishMap != null && englishMap.containsKey(key)) {
      return englishMap[key]!;
    }

    // Return key if no translation found
    return key;
  }

  static String get currentLanguage => _currentLanguage;

  static bool get isRTL => _currentLanguage == 'ar' || _currentLanguage == 'ku';

  static TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  static Locale get currentLocale {
    switch (_currentLanguage) {
      case 'ar':
        return const Locale('ar', 'IQ'); // Arabic (Iraq)
      case 'ku':
        return const Locale('ku', 'IQ'); // Kurdish (Iraq)
      default:
        return const Locale('en', 'US');
    }
  }

  static List<Locale> get supportedLocales => [
    const Locale('ar', 'IQ'),
    const Locale('ku', 'IQ'),
    const Locale('en', 'US'),
  ];

  static String formatCurrency(double amount, {String? currencyCode}) {
    final formatted = amount.toStringAsFixed(0);

    switch (_currentLanguage) {
      case 'ar':
        return '$formatted د.ع';
      case 'ku':
        return '$formatted دینار';
      default:
        return '$formatted IQD';
    }
  }

  static String formatDistance(double kilometers) {
    if (kilometers < 1) {
      final meters = (kilometers * 1000).round();
      switch (_currentLanguage) {
        case 'ar':
          return '$meters متر';
        case 'ku':
          return '$meters مەتر';
        default:
          return '${meters}m';
      }
    } else {
      final km = kilometers.toStringAsFixed(1);
      switch (_currentLanguage) {
        case 'ar':
          return '$km كم';
        case 'ku':
          return '$km کیلۆمەتر';
        default:
          return '${km}km';
      }
    }
  }

  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    switch (_currentLanguage) {
      case 'ar':
        final ampm = hour >= 12 ? 'مساءً' : 'صباحاً';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$hour12:$minute $ampm';
      case 'ku':
        return '${hour.toString().padLeft(2, '0')}:$minute';
      default:
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$hour12:$minute $ampm';
    }
  }

  // Helper method for getting directional text
  static String t(String key) => translate(key);
}
