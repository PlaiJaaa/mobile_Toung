import 'dart:convert';

import '../constant/api_config.dart';
import '../model/checklist_data.dart';
import '../model/destination_data.dart';
import '../model/packing_rule_data.dart';
import '../model/suggestion_data.dart';
import '../model/trip_data.dart';
import '../model/weather_data.dart';
import 'api_client.dart';

// ของแนะนำ "อย่าลืมเตรียม" รวมจาก 3 แหล่ง
// 1) packingRules จาก server (ตามประเภทสถานที่ / ตามประเทศ / ทุกทริป)
// 2) พยากรณ์อากาศ (เงื่อนไข if ในโค้ด)
// 3) จำนวนวันของทริป
class PackingService {
  // GET /packingRules : กฎของแนะนำทั้งหมด
  Future<List<PackingRuleData>> getRules() async {
    try {
      var response = await client
          .get(Uri.parse('$baseUrl/packingRules'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => PackingRuleData.fromJson(json)).toList();
      } else {
        throw ApiException('โหลดของแนะนำไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // ---------- เกณฑ์อากาศ ----------
  static const int rainyChance = 60; // โอกาสฝน (%) ตั้งแต่เท่านี้ แนะนำร่ม
  static const double coldTemp = 15; // ต่ำกว่านี้ (°C) แนะนำเสื้อกันหนาว
  static const double freezingTemp = 5; // ต่ำกว่านี้ แนะนำถุงมือ หมวกไหมพรม
  static const double hotTemp = 33; // ตั้งแต่นี้ขึ้นไป แนะนำแว่นกันแดด ขวดน้ำ

  // สร้างรายการของแนะนำทั้งหมดของทริป
  // weather = null แปลว่ายังไม่มีพยากรณ์ (ทริปไกลเกิน / ผ่านไปแล้ว / โหลดไม่สำเร็จ)
  static List<SuggestionData> buildSuggestions({
    required TripData trip,
    required DestinationData destination,
    required List<PackingRuleData> rules,
    List<WeatherData>? weather,
  }) {
    List<SuggestionData> all = [
      ...suggestionsFromWeather(trip, weather ?? []),
      ...suggestionsFromDays(trip),
      ...suggestionsFromRules(destination, rules),
    ];

    // ตัดรายการชื่อซ้ำ (เก็บอันแรกไว้ เพราะเหตุผลจากอากาศเจาะจงกว่า)
    List<SuggestionData> result = [];
    for (SuggestionData suggestion in all) {
      bool exists = result.any((s) => sameItem(s.item, suggestion.item));
      if (!exists) {
        result.add(suggestion);
      }
    }

    // ของจำเป็นขึ้นก่อน
    List<SuggestionData> essentials = result.where((s) => s.essential).toList();
    List<SuggestionData> others = result.where((s) => !s.essential).toList();
    return [...essentials, ...others];
  }

  // ---------- 1) จาก packingRules: กรองด้วย where ----------
  static List<SuggestionData> suggestionsFromRules(
    DestinationData destination,
    List<PackingRuleData> rules,
  ) {
    List<PackingRuleData> matched = rules.where((PackingRuleData rule) {
      if (rule.match == 'all') return true;
      if (rule.match == 'type') return rule.value == destination.type;
      if (rule.match == 'country') return rule.value == destination.country;
      return false;
    }).toList();

    return matched.map((PackingRuleData rule) {
      return SuggestionData(
        item: rule.item,
        reason: rule.reason,
        emoji: ruleEmoji(rule, destination),
        essential: rule.essential,
        source: ruleSource(rule, destination),
      );
    }).toList();
  }

  static String ruleEmoji(PackingRuleData rule, DestinationData destination) {
    if (rule.match == 'country') return '🛂';
    if (rule.match == 'type') {
      const Map<String, String> typeEmoji = {
        'beach': '🏖️',
        'mountain': '⛰️',
        'city': '🏙️',
        'temple': '🛕',
      };
      return typeEmoji[destination.type] ?? '📍';
    }
    return '🎒';
  }

  static String ruleSource(PackingRuleData rule, DestinationData destination) {
    if (rule.match == 'country') return 'ประเทศ${destination.country}';
    if (rule.match == 'type') return 'ที่เที่ยวแนว${destination.typeName}';
    return 'ทุกทริป';
  }

  // ---------- 2) จากพยากรณ์อากาศ: เงื่อนไข if ----------
  static List<SuggestionData> suggestionsFromWeather(
    TripData trip,
    List<WeatherData> weather,
  ) {
    List<SuggestionData> result = [];
    if (weather.isEmpty) {
      return result;
    }

    // ฝน: วันที่มีโอกาสฝนตกสูง
    List<WeatherData> rainyDays = weather
        .where((WeatherData w) => w.rainChance >= rainyChance)
        .toList();
    if (rainyDays.isNotEmpty) {
      int maxChance = rainyDays
          .map((WeatherData w) => w.rainChance)
          .reduce((a, b) => a > b ? a : b);
      result.add(
        SuggestionData(
          item: 'ร่มพับหรือเสื้อกันฝน',
          reason:
              '☔ เพราะพยากรณ์ว่าฝนตก${dayList(trip, rainyDays)} '
              '(โอกาสสูงสุด $maxChance%)',
          emoji: '☂️',
          essential: maxChance >= 80,
          source: 'พยากรณ์อากาศ',
        ),
      );
    }

    // หนาว: ดูวันที่อุณหภูมิต่ำสุดของทริป
    WeatherData coldest = weather.reduce(
      (a, b) => a.minTemp <= b.minTemp ? a : b,
    );
    if (coldest.minTemp < coldTemp) {
      result.add(
        SuggestionData(
          item: 'เสื้อกันหนาว',
          reason:
              '🥶 อุณหภูมิต่ำสุดราว ${coldest.minTemp.round()}°C '
              '${dayList(trip, [coldest])}',
          emoji: '🧥',
          essential: coldest.minTemp < 10,
          source: 'พยากรณ์อากาศ',
        ),
      );
    }
    if (coldest.minTemp < freezingTemp) {
      result.add(
        SuggestionData(
          item: 'ถุงมือ หมวกไหมพรม และผ้าพันคอ',
          reason: '❄️ หนาวจัด ต่ำสุดราว ${coldest.minTemp.round()}°C',
          emoji: '🧤',
          essential: false,
          source: 'พยากรณ์อากาศ',
        ),
      );
    }

    // หิมะ
    List<WeatherData> snowDays = weather
        .where((WeatherData w) => w.isSnow)
        .toList();
    if (snowDays.isNotEmpty) {
      result.add(
        SuggestionData(
          item: 'รองเท้ากันน้ำกันลื่น',
          reason: '🌨️ เพราะพยากรณ์ว่าหิมะตก${dayList(trip, snowDays)}',
          emoji: '🥾',
          essential: false,
          source: 'พยากรณ์อากาศ',
        ),
      );
    }

    // ร้อนจัด: ดูวันที่อุณหภูมิสูงสุดของทริป
    WeatherData hottest = weather.reduce(
      (a, b) => a.maxTemp >= b.maxTemp ? a : b,
    );
    if (hottest.maxTemp >= hotTemp) {
      String hotReason =
          '🥵 ร้อนจัด สูงสุดราว ${hottest.maxTemp.round()}°C '
          '${dayList(trip, [hottest])}';
      result.add(
        SuggestionData(
          item: 'แว่นกันแดด',
          reason: hotReason,
          emoji: '🕶️',
          essential: false,
          source: 'พยากรณ์อากาศ',
        ),
      );
      result.add(
        SuggestionData(
          item: 'ขวดน้ำพกพา',
          reason: '$hotReason ดื่มน้ำบ่อย ๆ กันฮีตสโตรก',
          emoji: '💧',
          essential: false,
          source: 'พยากรณ์อากาศ',
        ),
      );
    }
    return result;
  }

  // ข้อความบอกว่าเป็นวันที่เท่าไรของทริป เช่น "วันที่ 2, 3"
  static String dayList(TripData trip, List<WeatherData> days) {
    List<String> numbers = days.map((WeatherData w) {
      int day = w.date.difference(trip.startDate).inDays + 1;
      return day.toString();
    }).toList();
    return 'วันที่ ${numbers.join(', ')}';
  }

  // ---------- 3) จากจำนวนวันของทริป ----------
  static List<SuggestionData> suggestionsFromDays(TripData trip) {
    int days = trip.dayCount;
    int nights = days - 1;
    List<SuggestionData> result = [];

    if (days == 1) {
      result.add(
        SuggestionData(
          item: 'เสื้อผ้าสำรอง 1 ชุด',
          reason: '📅 ทริปไปเช้าเย็นกลับ เผื่อเปียกหรือเปื้อน',
          emoji: '👕',
          essential: false,
          source: 'จำนวนวัน',
        ),
      );
      return result;
    }

    // เกิน 7 วัน เตรียม 7 ชุดแล้วซักระหว่างทริป จะได้ไม่ต้องแบกเยอะ
    int outfits = days > 7 ? 7 : days;
    result.add(
      SuggestionData(
        item: 'เสื้อผ้า $outfits ชุด',
        reason: days > 7
            ? '📅 ทริป $days วัน $nights คืน เตรียม 7 ชุดแล้วซักระหว่างทริป'
            : '📅 ทริป $days วัน $nights คืน เตรียมวันละ 1 ชุด',
        emoji: '👕',
        essential: true,
        source: 'จำนวนวัน',
      ),
    );
    result.add(
      SuggestionData(
        item: 'ชุดชั้นในและถุงเท้า ${outfits + 1} ชุด',
        reason: '📅 ตามจำนวนวัน และเผื่อสำรองอีก 1 ชุด',
        emoji: '🧦',
        essential: false,
        source: 'จำนวนวัน',
      ),
    );
    if (days >= 4) {
      result.add(
        SuggestionData(
          item: 'ถุงแยกผ้าใช้แล้ว',
          reason: '📅 ทริปหลายวัน แยกผ้าใช้แล้วไม่ให้ปนกับผ้าสะอาด',
          emoji: '🧺',
          essential: false,
          source: 'จำนวนวัน',
        ),
      );
    }
    return result;
  }

  // ---------- กรองรายการที่ไม่ต้องแสดง ----------
  // ซ่อนของที่อยู่ในเช็กลิสต์แล้ว และของที่ผู้ใช้ปัดทิ้งในทริปนี้
  static List<SuggestionData> hideUsed(
    List<SuggestionData> suggestions,
    List<ChecklistData> checklist,
    List<String> dismissedItems,
  ) {
    return suggestions.where((SuggestionData s) {
      bool inChecklist = checklist.any((c) => sameItem(c.item, s.item));
      bool dismissed = dismissedItems.any((d) => sameItem(d, s.item));
      return !inChecklist && !dismissed;
    }).toList();
  }

  // เทียบชื่อของแบบไม่สนช่องว่างหัวท้ายและตัวพิมพ์เล็กใหญ่
  static bool sameItem(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }
}
