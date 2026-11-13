import 'package:flutter/material.dart';

import '../constant/app_format.dart';
import '../constant/color.dart';
import '../model/destination_data.dart';
import '../model/trip_data.dart';
import '../model/weather_data.dart';
import '../service/weather_service.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/weather_day_card.dart';

// แท็บสภาพอากาศ: พยากรณ์รายวันของปลายทางในช่วงวันที่ไป จาก Open-Meteo
// ทริปที่ผ่านไปแล้ว หรืออยู่ไกลเกินช่วงพยากรณ์ (16 วัน) จะแสดงข้อความอธิบายแทน
class WeatherTab extends StatefulWidget {
  final TripData trip;
  final DestinationData destination;

  const WeatherTab({super.key, required this.trip, required this.destination});

  @override
  State<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<WeatherTab>
    with AutomaticKeepAliveClientMixin {
  final WeatherService weatherService = WeatherService();

  List<WeatherData> _weather = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _unavailableReason; // มีค่า = ทริปนี้ดูพยากรณ์ไม่ได้

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _unavailableReason = WeatherService.unavailableReason(widget.trip);
    if (_unavailableReason == null) {
      loadWeather();
    } else {
      _isLoading = false;
    }
  }

  // GET https://api.open-meteo.com/v1/forecast?...
  Future<void> loadWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<WeatherData> list = await weatherService.getForecast(
        widget.destination,
        widget.trip,
      );
      if (!mounted) return;
      setState(() {
        _weather = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const LoadingView();
    }
    if (_unavailableReason != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          EmptyView(
            icon: widget.trip.isPast
                ? Icons.history_rounded
                : Icons.event_busy_rounded,
            title: widget.trip.isPast
                ? 'ทริปนี้ผ่านไปแล้ว'
                : 'ยังไม่มีพยากรณ์อากาศ',
            message: _unavailableReason!,
          ),
        ],
      );
    }
    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: loadWeather,
        child: ListView(
          children: [
            const SizedBox(height: 60),
            ErrorView(message: _errorMessage!, onRetry: loadWeather),
          ],
        ),
      );
    }
    return RefreshIndicator(onRefresh: loadWeather, child: buildForecast());
  }

  Widget buildForecast() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    TripData trip = widget.trip;

    // สรุปทั้งช่วง: ร้อนสุด หนาวสุด และจำนวนวันที่ฝนน่าจะตก
    double maxTemp = _weather.isEmpty
        ? 0
        : _weather.map((w) => w.maxTemp).reduce((a, b) => a > b ? a : b);
    double minTemp = _weather.isEmpty
        ? 0
        : _weather.map((w) => w.minTemp).reduce((a, b) => a < b ? a : b);
    int rainyDays = _weather.where((w) => w.rainChance >= 60).length;

    // บอกเมื่อพยากรณ์ครอบคลุมไม่ครบทุกวันของทริป
    List<String> notes = [];
    if (trip.startDate.isBefore(WeatherService.forecastStart(trip))) {
      notes.add('เริ่มแสดงตั้งแต่วันนี้ (วันก่อนหน้าผ่านไปแล้ว)');
    }
    if (trip.endDate.isAfter(WeatherService.forecastEnd(trip))) {
      notes.add(
        'แสดงถึงวันที่ ${formatDate(WeatherService.forecastEnd(trip))} '
        'วันหลังจากนั้นยังไกลเกินช่วงที่พยากรณ์ได้',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // การ์ดสรุป
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [infoColor, primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'พยากรณ์อากาศ ${widget.destination.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_weather.length} วัน · สูงสุด ${maxTemp.round()}°C · '
                'ต่ำสุด ${minTemp.round()}°C',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                rainyDays > 0
                    ? '☔ มีโอกาสฝนตกสูง $rainyDays วัน อย่าลืมพกร่ม'
                    : '🌤️ ไม่มีวันที่โอกาสฝนตกสูง',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (String note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colorScheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        for (WeatherData weather in _weather)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WeatherDayCard(
              weather: weather,
              dayNumber: weather.date.difference(trip.startDate).inDays + 1,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'ข้อมูลพยากรณ์จาก Open-Meteo.com (ใช้วันที่ตามเวลาท้องถิ่นของปลายทาง)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: colorScheme.outline),
        ),
      ],
    );
  }
}
