import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../model/destination_data.dart';
import 'destination_image.dart';

// ตัวเลือกปลายทาง 1 ใบในฟอร์มทริป แสดงรูป ชื่อ ประเทศ และประเภท
// ใบที่ถูกเลือกจะมีกรอบสีหลักหนาขึ้น (AnimatedContainer)
class DestinationOption extends StatelessWidget {
  final DestinationData destination;
  final bool isSelected;
  final VoidCallback onTap;

  const DestinationOption({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Theme.of(context).dividerColor,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DestinationImage(image: destination.image, height: 84),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primary,
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(
                  destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      destinationTypeIcons[destination.type],
                      size: 13,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${destination.typeName} · ${destination.country}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
