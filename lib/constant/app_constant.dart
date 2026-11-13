import 'package:flutter/material.dart';

import 'color.dart';

// ค่าคงที่ที่ใช้ทั้งแอป

const String appName = 'Travel Planner';

// ---------- สกุลเงิน (Dropdown ในฟอร์มทริป และตั้งค่าสกุลเงินหลัก) ----------
// key = รหัสสกุลเงินที่เก็บใน server, value = สัญลักษณ์ที่แสดงหน้าตัวเลข
const Map<String, String> currencySymbols = {
  'THB': '฿',
  'JPY': '¥',
  'KRW': '₩',
  'EUR': '€',
  'CHF': 'CHF ',
  'SGD': 'S\$',
  'IDR': 'Rp ',
  'LAK': '₭',
  'USD': '\$',
};

// ชื่อสกุลเงินภาษาไทย
const Map<String, String> currencyNames = {
  'THB': 'บาท',
  'JPY': 'เยน',
  'KRW': 'วอน',
  'EUR': 'ยูโร',
  'CHF': 'ฟรังก์สวิส',
  'SGD': 'ดอลลาร์สิงคโปร์',
  'IDR': 'รูเปียห์',
  'LAK': 'กีบ',
  'USD': 'ดอลลาร์สหรัฐ',
};

const String defaultCurrency = 'THB';

// ---------- สไตล์การเที่ยว (Radio ในฟอร์มทริป) ----------
const List<String> travelStyles = ['สบาย ๆ', 'ผจญภัย', 'ครอบครัว', 'ประหยัด'];

const Map<String, IconData> travelStyleIcons = {
  'สบาย ๆ': Icons.beach_access_rounded,
  'ผจญภัย': Icons.hiking_rounded,
  'ครอบครัว': Icons.family_restroom_rounded,
  'ประหยัด': Icons.savings_rounded,
};

// ---------- ประเภทสถานที่ (ช่อง type ของ destinations) ----------
const Map<String, String> destinationTypeNames = {
  'beach': 'ทะเล',
  'mountain': 'ภูเขา',
  'city': 'เมือง',
  'temple': 'วัด/โบราณสถาน',
};

const Map<String, IconData> destinationTypeIcons = {
  'beach': Icons.waves_rounded,
  'mountain': Icons.terrain_rounded,
  'city': Icons.location_city_rounded,
  'temple': Icons.temple_buddhist_rounded,
};

// ---------- หมวดกิจกรรม (แท็บแผนรายวัน) ----------
const List<String> activityCategories = ['กิน', 'เที่ยว', 'เดินทาง', 'ที่พัก'];

const Map<String, IconData> activityIcons = {
  'กิน': Icons.restaurant_rounded,
  'เที่ยว': Icons.photo_camera_rounded,
  'เดินทาง': Icons.directions_bus_rounded,
  'ที่พัก': Icons.hotel_rounded,
};

const Map<String, Color> activityColors = {
  'กิน': eatColor,
  'เที่ยว': visitColor,
  'เดินทาง': travelColor,
  'ที่พัก': stayColor,
};

// ---------- หมวดค่าใช้จ่าย (แท็บค่าใช้จ่าย) ----------
const List<String> expenseCategories = [
  'อาหาร',
  'ที่พัก',
  'เดินทาง',
  'ค่าเข้าชม/กิจกรรม',
  'ช้อปปิ้ง',
  'อื่น ๆ',
];

const Map<String, IconData> expenseIcons = {
  'อาหาร': Icons.restaurant_rounded,
  'ที่พัก': Icons.hotel_rounded,
  'เดินทาง': Icons.flight_rounded,
  'ค่าเข้าชม/กิจกรรม': Icons.confirmation_number_rounded,
  'ช้อปปิ้ง': Icons.shopping_bag_rounded,
  'อื่น ๆ': Icons.more_horiz_rounded,
};

const Map<String, Color> expenseColors = {
  'อาหาร': eatColor,
  'ที่พัก': stayColor,
  'เดินทาง': travelColor,
  'ค่าเข้าชม/กิจกรรม': visitColor,
  'ช้อปปิ้ง': Color(0xFF65A30D),
  'อื่น ๆ': Color(0xFF64748B),
};

// ---------- การเตือนก่อนเดินทาง ----------
// เหลือไม่เกินกี่วันก่อนวันไป จึงขึ้นแถบเตือนที่หน้าแรก
const int reminderDays = 3;
