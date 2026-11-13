import 'package:flutter/material.dart';

import '../constant/color.dart';

// รูปปลายทาง รองรับทั้งไฟล์ในแอป (assets/...) และ URL (http...)
// ถ้าโหลดรูปไม่ได้ จะแสดงพื้นไล่สีพร้อมไอคอนแทน แอปจึงไม่พัง
class DestinationImage extends StatelessWidget {
  final String image; // ช่อง image ของ destinations
  final double? height;

  const DestinationImage({super.key, required this.image, this.height});

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
      );
    }
    if (image.isEmpty) {
      return buildPlaceholder();
    }
    return Image.asset(
      image,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
    );
  }

  // พื้นหลังสำรองเมื่อไม่มีรูป
  Widget buildPlaceholder() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.landscape_rounded, size: 48, color: Colors.white),
    );
  }
}
