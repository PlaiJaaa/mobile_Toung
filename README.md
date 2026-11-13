# Travel Planner (แอปวางแผนเที่ยว)

Project รายวิชา Mobile Development เขียนด้วย Flutter
ใช้ REST API 2 แหล่ง: **json-server** (ข้อมูลทริปของเรา) และ **Open-Meteo** (พยากรณ์อากาศ ไม่ต้องใช้ API key)
ไม่มีระบบล็อกอิน (แอปใช้คนเดียว) ไม่ใช้ Firebase และจัดการ state ด้วย `StatefulWidget` + `setState` เท่านั้น

## วิธีรันแบบเร็วที่สุด

- **แค่อยากเปิดใช้แอป:** ดับเบิลคลิก **`run_apk.bat`** จะเปิด server, เปิด Android Emulator แล้วติดตั้งแอปจากไฟล์ `dist/TravelPlanner.apk` ที่ build ไว้แล้ว
  ต้องมีแค่ Node.js และ Android Studio **ไม่ต้องมี Flutter** (เลี่ยงปัญหาเวอร์ชัน Flutter / Gradle / Java ไม่ตรงกัน)
- **จะแก้โค้ด:** ดับเบิลคลิก **`run_all.bat`** จะเปิด server, เปิด emulator แล้ว `flutter run` ให้ (ต้องมี Flutter)

วิธีละเอียดทีละขั้น และวิธีรันบน Chrome ดูที่ [HOW_TO_RUN.md](HOW_TO_RUN.md)

> server ของแอปนี้ใช้ **port 3001** จึงเปิดพร้อมกับแอปอื่นที่ใช้ port 3000 (เช่น แอปหอพัก) ได้โดยไม่ชนกัน

## ฟีเจอร์

| หน้า | สิ่งที่ทำได้ |
| --- | --- |
| รายการทริป | การ์ดรูปปลายทาง (Stack) ชื่อ ปลายทาง ช่วงวันที่ และแถบงบที่ใช้ไปแล้ว แยก "กำลังจะไป" กับ "ไปแล้ว" ปุ่ม + สร้างทริป แก้ไข/ลบทริปจากเมนูการ์ด (ลบกิจกรรม รายจ่าย เช็กลิสต์ที่ผูกอยู่ด้วย) แถบเตือน "ยังไม่ได้เตรียม N อย่าง" เมื่อเหลือไม่เกิน 3 วันก่อนเดินทาง |
| ฟอร์มทริป | ชื่อทริป, เลือกปลายทาง (รูป + ประเภท), ช่วงวันที่ (`showDateRangePicker`), งบประมาณ, สกุลเงิน (Dropdown), สไตล์การเที่ยว (Radio) พร้อม validator |
| รายละเอียดทริป (TabBar 4 แท็บ) | **แผนรายวัน** กิจกรรมแยกตามวัน เพิ่ม/แก้ (PUT)/ลบ/ติ๊กทำแล้ว (PATCH) · **ค่าใช้จ่าย** ยอดรวมเทียบงบ แถบเปลี่ยนสีเมื่อใกล้/เกินงบ ยอดแยกหมวด เพิ่ม/ลบ · **เช็กลิสต์** เพิ่มเอง ติ๊กเตรียมแล้ว (PATCH + animation) และ "ของแนะนำสำหรับทริปนี้" · **สภาพอากาศ** พยากรณ์รายวันจาก Open-Meteo |
| ของแนะนำ "อย่าลืมเตรียม" | รวม 3 แหล่ง: packingRules จาก server (ตามประเภทสถานที่/ประเทศ/ทุกทริป), สภาพอากาศ (if ในโค้ด: ฝน หนาว หิมะ ร้อนจัด) และจำนวนวัน บอกเหตุผลทุกรายการ ของจำเป็นติดป้าย "อย่าลืม!" กดเพิ่มทีละชิ้น/เพิ่มทั้งหมด ซ่อนของที่อยู่ในเช็กลิสต์แล้ว ปัดทิ้งได้ (จำไว้ต่อทริป) |
| ตั้งค่า | สลับธีมสว่าง/มืด และสกุลเงินหลัก จำค่าด้วย shared_preferences |

## package ที่ใช้

| package | ใช้ทำอะไร |
| --- | --- |
| `http` | เรียก REST API (GET / POST / PUT / PATCH / DELETE) และ `MockClient` ในเทสต์ |
| `shared_preferences` | จำธีมและสกุลเงินหลักไว้ในเครื่อง |
| `intl` | จัดรูปแบบเงินและวันที่ภาษาไทย |
| `flutter_localizations` (มากับ Flutter SDK) | ปฏิทินและปุ่มของ widget สำเร็จรูปเป็นภาษาไทย |

ฟอนต์ไทย **Prompt** ฝังไว้ใน `assets/fonts` (สัญญาอนุญาต OFL) และรูปปลายทางฝังไว้ใน `assets/images` (ที่มาดู `assets/images/CREDITS.md`)

## API ที่เรียก

### json-server (`server/`, `http://localhost:3001`; บน Android Emulator คือ `http://10.0.2.2:3001`)

ตั้งที่อยู่ไว้จุดเดียวใน `lib/constant/api_config.dart`

| Method | Endpoint | ใช้ที่ไหน | ไฟล์ service |
| --- | --- | --- | --- |
| GET | `/trips` | หน้ารายการทริป | `trip_service.dart` |
| POST | `/trips` | สร้างทริป | `trip_service.dart` |
| PATCH | `/trips/{id}` | แก้ไขทริป / บันทึกของแนะนำที่ปัดทิ้ง (`dismissedItems`) | `trip_service.dart` |
| DELETE | `/trips/{id}` | ลบทริป (ลบข้อมูลลูกก่อน) | `trip_service.dart` |
| GET | `/destinations` | ฟอร์มทริป / รูปและพิกัดของปลายทาง | `destination_service.dart` |
| GET | `/activities?tripId={id}` | แท็บแผนรายวัน | `activity_service.dart` |
| POST | `/activities` | เพิ่มกิจกรรม | `activity_service.dart` |
| PUT | `/activities/{id}` | แก้ไขกิจกรรม | `activity_service.dart` |
| PATCH | `/activities/{id}` | ติ๊กว่าทำแล้ว `{ "isDone": true }` | `activity_service.dart` |
| DELETE | `/activities/{id}` | ลบกิจกรรม | `activity_service.dart` |
| GET | `/expenses` และ `/expenses?tripId={id}` | งบที่ใช้ไปในหน้ารายการ / แท็บค่าใช้จ่าย | `expense_service.dart` |
| POST | `/expenses` | บันทึกรายจ่าย | `expense_service.dart` |
| DELETE | `/expenses/{id}` | ลบรายจ่าย | `expense_service.dart` |
| GET | `/checklist` และ `/checklist?tripId={id}` | นับของที่ยังไม่เตรียม / แท็บเช็กลิสต์ | `checklist_service.dart` |
| POST | `/checklist` | เพิ่มของเอง / เพิ่มจากของแนะนำ | `checklist_service.dart` |
| PATCH | `/checklist/{id}` | ติ๊กว่าเตรียมแล้ว `{ "isPacked": true }` | `checklist_service.dart` |
| DELETE | `/checklist/{id}` | ลบรายการ | `checklist_service.dart` |
| GET | `/packingRules` | ของแนะนำตามประเภทสถานที่และประเทศ | `packing_service.dart` |

### Open-Meteo (`https://api.open-meteo.com/v1/forecast`)

| Method | พารามิเตอร์ | ใช้ที่ไหน |
| --- | --- | --- |
| GET | `latitude`, `longitude` (จาก destinations), `daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max`, `timezone=auto`, `start_date`, `end_date` | แท็บสภาพอากาศ และของแนะนำตามอากาศในแท็บเช็กลิสต์ (`weather_service.dart`) |

พยากรณ์ได้ล่วงหน้าประมาณ 16 วัน ทริปที่ไกลกว่านั้นหรือผ่านไปแล้วจะขึ้นข้อความอธิบายแทน

### การจัดการ error

ทุก service ใช้ `try/catch` + เช็ก `statusCode` แล้วแปลงเป็นข้อความภาษาไทย ทุกหน้าที่โหลดข้อมูลมีปุ่ม **ลองใหม่**
ถ้าปิด server จะขึ้น "เชื่อมต่อ server ไม่ได้ กรุณาเปิด server ก่อน" ถ้าเน็ตใช้ไม่ได้จะขึ้น "โหลดพยากรณ์อากาศไม่สำเร็จ..."
บันทึกสำเร็จขึ้น SnackBar สีเขียว และการลบทุกอย่างต้องยืนยันผ่าน Dialog ก่อน

## ชุดข้อมูลใน server

| ชุดข้อมูล | จำนวนตัวอย่าง | หมายเหตุ |
| --- | --- | --- |
| `destinations` | 14 แห่ง | ไทย 5, ญี่ปุ่น 3, เกาหลีใต้, ฝรั่งเศส, สวิตเซอร์แลนด์, อินโดนีเซีย, สิงคโปร์, ลาว มี `type` (beach/mountain/city/temple), `lat`, `lon`, `image` |
| `packingRules` | 49 ข้อ | `{ "match": "type" \| "country" \| "all", "value", "item", "reason", "essential" }` |
| `trips` | 3 ทริป | ภูเก็ต (ไปแล้ว), ฮอกไกโด (อีก 2 วัน เห็นแถบเตือนและพยากรณ์), ปารีส (อีกราว 2 เดือน) |
| `activities`, `expenses`, `checklist` | ผูกกับทริปด้วย `tripId` | |

`server/reset_db.js` สร้าง `db.json` จาก `db.sample.json` และ **เลื่อนวันที่ทริปให้ตรงกับวันนี้** ทุกครั้ง
จึงเดโมวันไหนก็ได้ผลเหมือนเดิม (ทริปฮอกไกโดจะเหลือ 2 วันก่อนเดินทางเสมอหลังรีเซ็ต)

## โครงสร้างไฟล์

```
lib/
├── main.dart                     # MaterialApp, ธีม, named routes ('/' และ '/trip-form'), ภาษาไทย
├── constant/
│   ├── api_config.dart           # ที่อยู่ server (port 3001) และ Open-Meteo จุดเดียว
│   ├── app_constant.dart         # สกุลเงิน สไตล์ ประเภทสถานที่ หมวดกิจกรรม/รายจ่าย
│   ├── app_format.dart           # จัดรูปแบบเงินและวันที่ (intl)
│   ├── color.dart                # สีของแอป
│   └── theme_data.dart           # ธีมสว่าง/มืด
├── model/                        # constructor + fromJson / toJson
│   ├── trip_data.dart  destination_data.dart  activity_data.dart
│   ├── expense_data.dart (ยอดรวมด้วย where/map)  checklist_data.dart
│   ├── packing_rule_data.dart  suggestion_data.dart  weather_data.dart
├── service/                      # เรียก API ด้วย http
│   ├── api_client.dart           # http.Client ที่ใช้ร่วมกัน + ApiException
│   ├── trip_service.dart  destination_service.dart  activity_service.dart
│   ├── expense_service.dart  checklist_service.dart
│   ├── packing_service.dart      # GET packingRules + รวมของแนะนำ 3 แหล่ง
│   ├── weather_service.dart      # Open-Meteo
│   └── pref_service.dart         # shared_preferences
├── screens/
│   ├── main_screen.dart          # BottomNavigationBar (ทริป / ตั้งค่า)
│   ├── trip_list_screen.dart  trip_form_screen.dart  trip_detail_screen.dart (TabBar)
│   ├── plan_tab.dart  activity_form_screen.dart
│   ├── expense_tab.dart  expense_form_screen.dart
│   ├── checklist_tab.dart  weather_tab.dart  settings_screen.dart
└── widgets/                      # custom widget ที่ใช้ซ้ำ
    ├── trip_card.dart  budget_bar.dart (AnimatedContainer)  reminder_banner.dart
    ├── activity_tile.dart (AnimatedOpacity)  checklist_tile.dart (AnimatedContainer)
    ├── suggestion_card.dart  expense_tile.dart  weather_day_card.dart
    ├── destination_image.dart  destination_option.dart
    └── app_snack_bar.dart  confirm_dialog.dart  error_view.dart  empty_view.dart
        loading_view.dart  primary_button.dart  section_title.dart
server/   db.sample.json, db.json, reset_db.js, package.json (json-server 0.17.4)
test/     model_test, service_test, packing_test, app_flow_test (MockClient จาก package:http/testing.dart)
```

## ตรวจคุณภาพ

```bat
flutter analyze
flutter test
```
