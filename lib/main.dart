import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constant/app_constant.dart';
import 'constant/theme_data.dart';
import 'screens/main_screen.dart';
import 'screens/trip_form_screen.dart';
import 'service/pref_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // โหลดข้อมูลชื่อวันและเดือนภาษาไทยให้ package intl
  await initializeDateFormatting('th');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PrefService prefService = PrefService();

  ThemeMode _themeMode = ThemeMode.light; // ค่าเริ่มต้นเป็น Light Mode
  String _mainCurrency = defaultCurrency; // สกุลเงินหลัก (ค่าเริ่มต้นของทริปใหม่)

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // อ่านธีมและสกุลเงินหลักที่ผู้ใช้เคยเลือกไว้จาก shared_preferences
  void loadSettings() async {
    bool isDark = await prefService.getDarkMode();
    String currency = await prefService.getMainCurrency();
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _mainCurrency = currency;
    });
  }

  // สลับธีมสว่าง/มืด แล้วจำค่าไว้ในเครื่อง
  void toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.light)
          ? ThemeMode.dark
          : ThemeMode.light;
    });
    prefService.saveDarkMode(_themeMode == ThemeMode.dark);
  }

  // หน้าตั้งค่าเรียกเมื่อผู้ใช้เปลี่ยนสกุลเงินหลัก
  void changeMainCurrency(String currency) {
    setState(() {
      _mainCurrency = currency;
    });
    prefService.saveMainCurrency(currency);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode, // set theme เปลี่ยนได้ตรงนี้
      theme: lightTheme,
      darkTheme: darkTheme,

      // ให้ widget สำเร็จรูป (ปฏิทิน, ปุ่มยกเลิก/ตกลง) แสดงเป็นภาษาไทย
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      initialRoute: '/', // เส้นทางเริ่มต้น
      routes: {
        // ส่งฟังก์ชันสลับธีม/เปลี่ยนสกุลเงินให้หน้าหลักผ่าน constructor
        '/': (context) => MainScreen(
          switchMode: toggleTheme,
          onCurrencyChanged: changeMainCurrency,
        ),
        // ฟอร์มสร้างทริปใหม่ ใช้สกุลเงินหลักเป็นค่าเริ่มต้น
        '/trip-form': (context) =>
            TripFormScreen(defaultCurrency: _mainCurrency),
      },
      // จำกัดความกว้างสูงสุดของแอป ให้เปิดบนเว็บหรือจอกว้างแล้วยังเป็นสัดส่วนมือถือ
      builder: (context, child) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
