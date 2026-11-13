import 'package:flutter/material.dart';

import '../constant/api_config.dart';
import '../constant/app_constant.dart';
import '../service/pref_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/section_title.dart';

// หน้าตั้งค่า: สลับธีม และตั้งสกุลเงินหลัก (จำค่าด้วย shared_preferences)
class SettingsScreen extends StatefulWidget {
  final VoidCallback switchMode; // ฟังก์ชันสลับธีมจาก main.dart
  final ValueChanged<String> onCurrencyChanged; // แจ้ง main.dart ว่าเปลี่ยนสกุลเงินหลัก

  const SettingsScreen({
    super.key,
    required this.switchMode,
    required this.onCurrencyChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PrefService prefService = PrefService();
  String? _mainCurrency; // null = กำลังอ่านค่าจากเครื่อง

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  void loadCurrency() async {
    String currency = await prefService.getMainCurrency();
    if (!mounted) return;
    setState(() {
      _mainCurrency = currency;
    });
  }

  void changeCurrency(String? currency) {
    if (currency == null) return;
    setState(() {
      _mainCurrency = currency;
    });
    widget.onCurrencyChanged(currency); // main.dart บันทึกลง shared_preferences
    showSuccessSnackBar(
      context,
      'ตั้งสกุลเงินหลักเป็น ${currencyNames[currency]} แล้ว',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // อ่านธีมปัจจุบันจาก Theme ของแอป (main.dart เป็นคนเก็บค่า)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionTitle(title: 'การแสดงผล'),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              secondary: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  color: colorScheme.primary,
                ),
              ),
              title: const Text('โหมดมืด'),
              subtitle: Text(isDark ? 'ใช้ธีมมืดอยู่' : 'ใช้ธีมสว่างอยู่'),
              value: isDark,
              onChanged: (bool value) => widget.switchMode(),
            ),
          ),
          const SizedBox(height: 20),

          const SectionTitle(title: 'สกุลเงินหลัก'),
          const SizedBox(height: 4),
          Text(
            'ใช้เป็นค่าเริ่มต้นตอนสร้างทริปใหม่ (แต่ละทริปเปลี่ยนสกุลเงินเองได้)',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (_mainCurrency != null)
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _mainCurrency,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.currency_exchange_rounded),
              ),
              items: currencySymbols.keys.map((String code) {
                return DropdownMenuItem(
                  value: code,
                  child: Text(
                    '$code · ${currencyNames[code]} (${currencySymbols[code]!.trim()})',
                  ),
                );
              }).toList(),
              onChanged: changeCurrency,
            ),
          const SizedBox(height: 20),

          const SectionTitle(title: 'เกี่ยวกับแอป'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.travel_explore_rounded),
                  title: Text(appName),
                  subtitle: Text('แอปวางแผนเที่ยว เวอร์ชัน 1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('ข้อมูลทริป (json-server)'),
                  subtitle: Text(baseUrl),
                ),
                const ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('พยากรณ์อากาศ'),
                  subtitle: Text('Open-Meteo.com (ไม่ต้องใช้ API key)'),
                ),
                const ListTile(
                  leading: Icon(Icons.photo_outlined),
                  title: Text('รูปปลายทาง'),
                  subtitle: Text('Wikimedia Commons (ดู assets/images/CREDITS.md)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
