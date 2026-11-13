import 'package:flutter/material.dart';

import 'settings_screen.dart';
import 'trip_list_screen.dart';

// หน้าหลัก มี BottomNavigationBar 2 เมนู: ทริป / ตั้งค่า
class MainScreen extends StatefulWidget {
  final VoidCallback switchMode; // ฟังก์ชันสลับธีมจาก main.dart
  final ValueChanged<String> onCurrencyChanged; // เปลี่ยนสกุลเงินหลัก

  const MainScreen({
    super.key,
    required this.switchMode,
    required this.onCurrencyChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // หน้าของแต่ละเมนู key ใช้บอก AnimatedSwitcher ว่าเป็นคนละหน้ากัน
    final List<Widget> widgetOptions = <Widget>[
      const TripListScreen(key: ValueKey(0)),
      SettingsScreen(
        key: const ValueKey(1),
        switchMode: widget.switchMode,
        onCurrencyChanged: widget.onCurrencyChanged,
      ),
    ];

    return Scaffold(
      // AnimatedSwitcher: จางสลับหน้าเมื่อเปลี่ยนเมนู
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage_outlined),
            activeIcon: Icon(Icons.luggage_rounded),
            label: 'ทริป',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'ตั้งค่า',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
