import 'package:flutter/material.dart';

// ปุ่มหลักเต็มความกว้าง ระหว่างกำลังบันทึกจะสลับเป็นวงกลมหมุนและกดซ้ำไม่ได้
class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        // onPressed เป็น null = ปุ่มถูกปิด กันการกดซ้ำระหว่างบันทึก
        onPressed: isLoading ? null : onPressed,
        // AnimatedSwitcher: ค่อย ๆ สลับระหว่างข้อความกับวงกลมหมุน
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  key: const ValueKey('text'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(text),
                  ],
                ),
        ),
      ),
    );
  }
}
