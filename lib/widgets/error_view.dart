import 'package:flutter/material.dart';

import '../constant/color.dart';

// แสดงเมื่อโหลดข้อมูลจาก server ไม่สำเร็จ พร้อมปุ่มลองใหม่
class ErrorView extends StatelessWidget {
  final String message; // ข้อความ error ภาษาไทย (เช่น ให้เปิด server ก่อน)
  final VoidCallback? onRetry; // กดแล้วโหลดใหม่ (ไม่ส่งมา = ไม่มีปุ่ม)

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: dangerColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: dangerColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'โหลดข้อมูลไม่สำเร็จ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองใหม่'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
