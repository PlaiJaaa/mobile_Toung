// Model กฎของแนะนำ (GET /packingRules)
// ตัวอย่าง { "match": "type", "value": "beach", "item": "ครีมกันแดด", "reason": "...", "essential": false }
class PackingRuleData {
  final String id;
  final String match; // type = ตามประเภทสถานที่, country = ตามประเทศ, all = ทุกทริป
  final String value; // ค่าที่ต้องตรง เช่น beach หรือ ญี่ปุ่น (match = all ไม่ใช้)
  final String item; // ของที่แนะนำ
  final String reason; // เหตุผลที่แนะนำ
  final bool essential; // ของจำเป็น (ติดป้าย "อย่าลืม!")

  // Constructor
  PackingRuleData({
    required this.id,
    required this.match,
    required this.value,
    required this.item,
    required this.reason,
    required this.essential,
  });

  // แปลง JSON เป็น Object
  PackingRuleData.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      match = json['match'] ?? 'all',
      value = json['value'] ?? '',
      item = json['item'] ?? '',
      reason = json['reason'] ?? '',
      essential = json['essential'] ?? false;

  // แปลง Object เป็น JSON Map
  Map<String, dynamic> toJson() {
    return {
      'match': match,
      'value': value,
      'item': item,
      'reason': reason,
      'essential': essential,
    };
  }
}
