// استيراد المكتبات والملفات الضرورية
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للتحكم في خدمات النظام مثل اتجاه الشاشة.
import 'package:flutter_localizations/flutter_localizations.dart'; // لدعم التعريب واللغات.
import 'package:google_fonts/google_fonts.dart'; // لاستخدام خطوط جوجل.
import 'screens/home_screen.dart'; // استيراد الشاشة الرئيسية للتطبيق.

// استيرادات Firebase الضرورية
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // هذا الملف تم إنشاؤه بواسطة flutterfire configure

//------------------------------------------------------------------------------

/// دالة main هي نقطة البداية لتشغيل التطبيق.
/// يجب أن تكون async لتهيئة Firebase قبل تشغيل واجهة المستخدم.
void main() async {
  // التأكد من تهيئة جميع الروابط اللازمة قبل تشغيل التطبيق.
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase باستخدام الخيارات الافتراضية للمنصة الحالية.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تحديد اتجاهات الشاشة المسموح بها للتطبيق (هنا، فقط الوضع العمودي).
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // تشغيل التطبيق عن طريق تمرير الويدجت الجذر (Root Widget).
  runApp(const MyApp());
}

//------------------------------------------------------------------------------

/// الويدجت الجذر للتطبيق، وهو من نوع StatelessWidget لأنه لا يحتوي على حالة داخلية تتغير.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //------------------------------------------------------------------------------

  /// دالة build هي المسؤولة عن بناء واجهة المستخدم للويدجت.
  @override
  Widget build(BuildContext context) {
    // إنشاء الثيم (Theme) الأساسي للتطبيق باستخدام نظام الألوان Material 3.
    final baseTheme = ThemeData(
      // إنشاء نظام ألوان متناسق بناءً على لون أساسي واحد (seedColor).
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF006666), // اللون الأساسي (Teal).
        brightness: Brightness.light, // تحديد أن الثيم هو الثيم الفاتح.
      ),
      useMaterial3: true, // تفعيل تصميم Material 3.
    );

    // بناء الويدجت الرئيسي للتطبيق (MaterialApp).
    return MaterialApp(
      title: 'نظام إدارة المعامل', // عنوان التطبيق الذي يظهر في مدير المهام.
      debugShowCheckedModeBanner:
          false, // إخفاء شريط "Debug" في الزاوية العلوية.

      // --- إعدادات التعريب واللغة العربية ---
      locale: const Locale(
          'ar', 'SA'), // تحديد اللغة الافتراضية للتطبيق (العربية - السعودية).
      // تحديد المندوبين المسؤولين عن ترجمة نصوص واجهة المستخدم القياسية.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // تحديد اللغات التي يدعمها التطبيق.
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],

      // --- تخصيص الثيم (Theme) ---
      // استخدام `copyWith` لتخصيص الثيم الأساسي دون تغييره بالكامل.
      theme: baseTheme.copyWith(
        // استخدام خط "Cairo" من Google Fonts لجميع النصوص في التطبيق.
        textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme),
        // تخصيص المظهر الموحد لجميع أشرطة العناوين (AppBar).
        appBarTheme: AppBarTheme(
          centerTitle: true, // توسيط العنوان.
          backgroundColor: baseTheme.colorScheme.primary, // لون الخلفية.
          foregroundColor:
              baseTheme.colorScheme.onPrimary, // لون النصوص والأيقونات.
          elevation: 2, // درجة الظل.
        ),
        // تخصيص المظهر الموحد لجميع البطاقات (Card).
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // حواف دائرية.
          ),
        ),
        // تخصيص المظهر الموحد لجميع حقول الإدخال (TextFormField, TextField).
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: baseTheme.colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: baseTheme.colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: baseTheme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: baseTheme.colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: baseTheme.colorScheme.error, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // تخصيص المظهر الموحد للأزرار المعبأة (FilledButton).
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        // تخصيص المظهر الموحد للأزرار النصية (TextButton).
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      // تحديد الشاشة الرئيسية التي ستظهر عند تشغيل التطبيق.
      home: const HomeScreen(),
    );
  }
}
