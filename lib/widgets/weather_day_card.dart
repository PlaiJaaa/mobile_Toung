import 'package:flutter/material.dart';

import '../constant/app_format.dart';
import '../constant/color.dart';
import '../model/weather_data.dart';

// การ์ดพยากรณ์อากาศ 1 วัน: วันที่ของทริป ไอคอน อุณหภูมิสูง/ต่ำ และโอกาสฝน
class WeatherDayCard extends StatelessWidget {
  final WeatherData weather;
  final int dayNumber; // วันที่เท่าไรของทริป

  const WeatherDayCard({
    super.key,
    required this.weather,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isRainy = weather.rainChance >= 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'วันที่ $dayNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    formatDayDate(weather.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(weather.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_rounded,
                        size: 14,
                        color: isRainy ? infoColor : colorScheme.outline,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'โอกาสฝน ${weather.rainChance}%',
                        style: TextStyle(
                          fontSize: 13,
                          color: isRainy
                              ? infoColor
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isRainy ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weather.maxTemp.round()}°',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: secondaryColor,
                  ),
                ),
                Text(
                  '${weather.minTemp.round()}°',
                  style: const TextStyle(fontSize: 14, color: infoColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
