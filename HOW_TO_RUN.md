# วิธีรันแอป Travel Planner (ทีละขั้น)

แอปนี้มี 2 ส่วนที่ต้องเปิดพร้อมกัน

1. **server** (โฟลเดอร์ `server/`): REST API จาก json-server เก็บข้อมูลในไฟล์ `server/db.json` ใช้ **port 3001**
2. **แอป Flutter**: รันบน Android Emulator หรือ Chrome แล้วเรียก API จาก server
   (แท็บสภาพอากาศเรียก Open-Meteo ผ่านอินเทอร์เน็ต จึงต้องต่อเน็ตด้วย)

ต้อง **เปิด server ก่อนเสมอ** แล้วจึงรันแอป ไม่อย่างนั้นแอปจะขึ้นว่า "เชื่อมต่อ server ไม่ได้ กรุณาเปิด server ก่อน"

มี 2 วิธีให้เลือก

| วิธี | ใช้เมื่อ | ต้องติดตั้ง |
| --- | --- | --- |
| **`run_apk.bat`** (แนะนำสำหรับแค่เปิดใช้แอป) | อยากเปิดแอปดูหรือเดโมเลย ไม่ได้จะแก้โค้ด หรือเครื่อง build Android ไม่ผ่าน | Node.js + Android Studio (ไม่ต้องมี Flutter) |
| **`run_all.bat`** | จะแก้โค้ดแล้วรันใหม่ หรือใช้ hot reload | Flutter + Node.js + Android Studio |

## วิธีที่ 1: เปิดแอปจากไฟล์ APK สำเร็จรูป (`run_apk.bat`)

ใช้ไฟล์ `dist/TravelPlanner.apk` ที่ build ไว้แล้ว **เครื่องที่ใช้ไม่ต้อง build เอง** จึงไม่มีปัญหาเรื่องเวอร์ชัน Flutter / Gradle / Java

### ติดตั้งโปรแกรม (ทำครั้งเดียว)

1. **Node.js** รุ่น LTS จาก https://nodejs.org (กด Next ไปจนจบ)
2. **Android Studio** จาก https://developer.android.com/studio
   - เปิดครั้งแรกให้เลือก Standard แล้วรอโหลด Android SDK จนเสร็จ
3. **สร้าง emulator** (ถ้ายังไม่มี) ใน Android Studio > More Actions (หรือเมนู Tools) > **Device Manager** > ปุ่ม **+** > Create Virtual Device
   - เลือกเครื่อง เช่น Pixel 8 > Next > เลือก system image ที่มีคำว่า **x86_64** (กดลูกศรดาวน์โหลดถ้ายังไม่มี) > Next > Finish
4. เปิด Command Prompt **หน้าต่างใหม่** แล้วเช็กว่าติดตั้ง Node.js แล้ว

   ```bat
   node --version
   ```

### เปิดแอป

1. ดับเบิลคลิก **`run_apk.bat`** ในโฟลเดอร์โปรเจกต์
2. รอจนสคริปต์ทำครบ 3 ขั้น (ครั้งแรกประมาณ 2-4 นาที)

   ```
   [1/3] ตรวจ server ...            -> เปิดหน้าต่าง "Travel Planner server" ให้เอง ห้ามปิดหน้าต่างนั้น
   [2/3] ตรวจ Android Emulator ...  -> เปิด emulator ให้เอง แล้วรอจน boot เสร็จ
   [3/3] ติดตั้งแอปจากไฟล์ ...       -> ขึ้น Success แล้วแอปจะเปิดขึ้นบน emulator เอง
   ```

3. เมื่อขึ้นข้อความ `เปิดแอป Travel Planner บน emulator แล้ว` ก็ใช้แอปบน emulator ได้เลย
   หน้าต่าง `run_apk.bat` กดปุ่มใดก็ได้เพื่อปิดได้ แอปยังเปิดอยู่
4. ครั้งต่อไปจะเปิดแอปจากไอคอน **Travel Planner** ในหน้ารวมแอปของ emulator ก็ได้ แต่ต้องเปิด server ก่อน (ดับเบิลคลิก `start_server.bat`)
   หรือดับเบิลคลิก `run_apk.bat` ซ้ำ ซึ่งจะเปิดให้ครบทุกอย่างอีกครั้ง

### ปิดทุกอย่าง

1. ปิดหน้าต่าง **"Travel Planner server"** (หรือหน้าต่าง cmd ที่ขึ้นว่า `npm start` / `Watching...`) = ปิด server
2. กด X ที่หน้าต่าง emulator = ปิด emulator

ข้อมูลที่เพิ่มหรือแก้ในแอปเก็บอยู่ใน `server/db.json` ถ้าอยากล้างกลับเป็นข้อมูลตัวอย่าง ดับเบิลคลิก `reset_data.bat`

### ถ้าเจอปัญหา

| ข้อความ | วิธีแก้ |
| --- | --- |
| `[ผิดพลาด] ไม่พบ Node.js` | ติดตั้ง Node.js แล้ว **เปิดไฟล์ใหม่** (ถ้ายังไม่หายให้รีสตาร์ตเครื่อง) |
| `[ผิดพลาด] ไม่พบ Android SDK` | เปิด Android Studio ให้โหลด SDK จนเสร็จก่อน ถ้าติดตั้ง SDK ไว้ที่อื่น ให้ตั้ง `ANDROID_HOME` ชี้ไปที่โฟลเดอร์นั้น |
| `[ผิดพลาด] ยังไม่มี emulator ในเครื่อง` | สร้าง emulator ตามข้อ 3 ด้านบน |
| `[ผิดพลาด] emulator boot ไม่เสร็จภายใน 3 นาที` | เปิด emulator จาก Device Manager เองให้ขึ้นหน้า Home ก่อน แล้วดับเบิลคลิก `run_apk.bat` ใหม่ ถ้าค้างให้กด ▼ ข้างปุ่ม ▶ > **Cold Boot Now** |
| `INSTALL_FAILED_...` | สคริปต์จะลบแอปเดิมแล้วติดตั้งใหม่ให้เองถ้าลายเซ็นไม่ตรง ถ้ายังไม่ผ่าน ให้ลบแอป Travel Planner ใน emulator เอง (กดค้างที่ไอคอน > Uninstall) แล้วลองใหม่ |
| แอปขึ้นว่า "เชื่อมต่อ server ไม่ได้" | ดูว่าหน้าต่าง server ยังเปิดอยู่ ถ้าไม่ ดับเบิลคลิก `start_server.bat` แล้วกด **ลองใหม่** ในแอป |
| แท็บสภาพอากาศโหลดไม่ได้ | ตรวจว่าคอมพิวเตอร์ต่อเน็ตได้ แล้วกด **ลองใหม่** (ข้อมูลอากาศมาจาก Open-Meteo ผ่านอินเทอร์เน็ต) |

> ไฟล์ APK นี้ใช้ได้กับ **Android Emulator** เท่านั้น เพราะแอปเรียก server ที่ `10.0.2.2:3001` ซึ่งเป็นที่อยู่ของคอมพิวเตอร์เมื่อมองจาก emulator
> ถ้าแก้โค้ด ต้อง build APK ใหม่ด้วยคำสั่ง `flutter build apk --release` แล้วคัดลอก `build\app\outputs\flutter-apk\app-release.apk` ไปทับ `dist\TravelPlanner.apk`

---

## วิธีที่ 2: ทางลัดสำหรับนักพัฒนา ดับเบิลคลิก `run_all.bat` ครั้งเดียว

ถ้าติดตั้งโปรแกรมใน [ขั้นที่ 1](#ขั้นที่-1-ติดตั้งโปรแกรม-ทำครั้งเดียว) ครบแล้ว และมี Android Emulator อย่างน้อย 1 เครื่อง
ดับเบิลคลิก **`run_all.bat`** ไฟล์เดียวจะทำให้ครบทั้ง 3 อย่าง

1. ตรวจว่ามี flutter, node และ Android SDK ถ้าขาดจะบอกเป็นภาษาไทยว่าต้องติดตั้งอะไร
2. เปิด server ในหน้าต่างใหม่ชื่อ "Travel Planner server" แล้วรอจนเรียก `http://127.0.0.1:3001/trips` ได้ (ถ้าเปิดอยู่แล้วจะข้าม)
3. เปิด emulator เครื่องแรกที่มีในเครื่อง แล้วรอจน boot เสร็จ (ถ้าเปิดอยู่แล้วจะใช้เครื่องนั้น)
4. รัน `flutter pub get` และ `flutter run -d emulator` จนแอปขึ้นบน emulator

ครั้งแรกรวมแล้วใช้เวลาประมาณ 3-7 นาที (ส่วนใหญ่คือ build Android) ครั้งต่อไปเร็วขึ้นมาก

- จะมี **2 หน้าต่าง**: หน้าต่าง `run_all.bat` (แอป) และหน้าต่าง "Travel Planner server" อย่าปิดหน้าต่าง server ระหว่างใช้แอป
- ปิดแอป: กด `q` ในหน้าต่าง `run_all.bat` ส่วน server และ emulator ยังเปิดอยู่ กด `run_all.bat` ซ้ำได้เลย
- เลิกใช้งาน: ปิดหน้าต่าง "Travel Planner server" และปิด emulator
- แอปนี้ใช้ port **3001** จึงเปิดพร้อมกับแอปอื่นที่ใช้ port 3000 (เช่น แอปหอพัก) ได้ ถ้า port 3001 ถูกโปรแกรมอื่นใช้อยู่ `run_all.bat` จะขึ้นข้อความบอกให้ปิดโปรแกรมนั้นก่อน

ถ้าอยากรันบน Chrome หรือทำทีละขั้นเอง ทำตามขั้นที่ 2-3 ด้านล่าง

---

## ขั้นที่ 1 ติดตั้งโปรแกรม (ทำครั้งเดียว)

| โปรแกรม | ใช้ทำอะไร | ดาวน์โหลด |
| --- | --- | --- |
| Flutter SDK 3.32 ขึ้นไป | รันแอป | https://docs.flutter.dev/get-started/install/windows |
| Node.js 18 ขึ้นไป (แนะนำรุ่น LTS) | รัน server (มี npm มาด้วย) | https://nodejs.org |
| Android Studio | มี Android SDK และ Android Emulator | https://developer.android.com/studio |
| Google Chrome | ถ้าจะรันแอปบนเว็บ | https://www.google.com/chrome |
| VS Code + ส่วนเสริม Flutter (ไม่บังคับ) | เปิดโค้ดและกด F5 เพื่อรัน | https://code.visualstudio.com |

ติดตั้งเสร็จแล้ว เปิด Command Prompt หรือ PowerShell **หน้าต่างใหม่** แล้วเช็กเวอร์ชัน

```bat
flutter --version
node --version
npm --version
flutter doctor
```

ตัวอย่างผลบนเครื่องที่ใช้ทดสอบ: Flutter 3.32.7, Node v22.20.0
ใน `flutter doctor` ให้ดูว่าบรรทัด **Flutter**, **Android toolchain** และ **Chrome** ขึ้นเครื่องหมายถูก
(ถ้าบอกว่า Android licenses ยังไม่ยอมรับ ให้รัน `flutter doctor --android-licenses` แล้วตอบ `y`)

---

## ขั้นที่ 2 เปิด server

### วิธีที่ง่ายที่สุด

ดับเบิลคลิกไฟล์ **`start_server.bat`** ในโฟลเดอร์โปรเจกต์

- ครั้งแรกจะติดตั้ง package ให้เอง (`npm install` ใช้เวลาประมาณ 10-30 วินาที ต้องต่ออินเทอร์เน็ต)
- ถ้ายังไม่มี `server/db.json` จะสร้างจากข้อมูลตัวอย่างให้ (และเลื่อนวันที่ทริปให้ตรงกับวันนี้)
- **ทิ้งหน้าต่างนี้เปิดไว้ตลอดที่ใช้แอป** ปิดหน้าต่าง = ปิด server

### หรือพิมพ์คำสั่งเอง

```bat
cd server
npm install
npm start
```

### รู้ได้อย่างไรว่าเปิดสำเร็จ

1. ในหน้าต่าง server จะมีข้อความ

   ```
   \{^_^}/ hi!
   Loading db.json
   Done
   Resources
   http://127.0.0.1:3001/destinations
   http://127.0.0.1:3001/packingRules
   http://127.0.0.1:3001/trips
   ...
   Watching...
   ```

2. เปิดเบราว์เซอร์ไปที่ **http://localhost:3001/trips** ต้องเห็นข้อมูลทริปเป็น JSON
   (ลอง http://localhost:3001/destinations, http://localhost:3001/packingRules ได้เช่นกัน)

ทุกครั้งที่แอปเรียก API หน้าต่าง server จะแสดงบรรทัด เช่น `GET /trips 200` หรือ `PATCH /checklist/7 200`
ใช้ดูได้ว่าแอปเรียก method อะไร

---

## ขั้นที่ 3 รันแอป

เปิด Command Prompt **หน้าต่างใหม่** (หน้าต่าง server ต้องเปิดค้างไว้) แล้วเข้าโฟลเดอร์โปรเจกต์
(โฟลเดอร์ที่มีไฟล์ `pubspec.yaml` เช่น `cd D:\Mobile_Toung`)

```bat
flutter pub get
```

### แบบที่ 1: Android Emulator

1. เปิด emulator ด้วยวิธีใดวิธีหนึ่ง
   - Android Studio > **Device Manager** > กดปุ่ม ▶ ที่เครื่องที่ต้องการ
   - หรือใช้คำสั่ง

     ```bat
     flutter emulators
     flutter emulators --launch flutter_emulator
     ```

     (`flutter_emulator` คือชื่อเครื่องบนเครื่องที่ใช้ทดสอบ ให้เปลี่ยนเป็นชื่อที่ `flutter emulators` แสดง)
2. รอจนเห็นหน้า Home ของ Android แล้วเช็กว่า Flutter มองเห็น

   ```bat
   flutter devices
   ```

   ต้องมีบรรทัดที่ขึ้นต้นด้วย `sdk gphone ... • emulator-5554`
3. รันแอป

   ```bat
   flutter run -d emulator
   ```

   ครั้งแรกจะ build นาน 2-5 นาที ครั้งต่อไปเร็วขึ้นมาก

### แบบที่ 2: Chrome

```bat
flutter run -d chrome
```

Flutter จะเปิดหน้าต่าง Chrome ใหม่ให้เอง (ครั้งแรกใช้เวลาประมาณ 30 วินาที)

### แบบที่ 3: กด F5 ใน VS Code

1. เปิดโฟลเดอร์โปรเจกต์ (ที่มี `pubspec.yaml`) ใน VS Code
2. ไปที่แถบ **Run and Debug** (Ctrl+Shift+D) เลือกจากรายการด้านบน
   - **Travel Planner: Android Emulator** (ต้องเปิด emulator ไว้ก่อน)
   - **Travel Planner: Chrome**
3. กด **F5**

---

## ขั้นที่ 4 ลองใช้งาน (ข้อมูลตัวอย่าง)

| ทริป | สถานะหลังรีเซ็ตข้อมูล | ใช้เดโมอะไร |
| --- | --- | --- |
| ทะเลภูเก็ตกับครอบครัว | ไปแล้ว (เดือนก่อน) | ส่วน "ไปแล้ว", กิจกรรมติ๊กครบ, แท็บอากาศขึ้นว่าทริปผ่านไปแล้ว |
| ฮอกไกโดหน้าหนาว | อีก 2 วันออกเดินทาง | แถบเตือน "ยังไม่ได้เตรียม 5 อย่าง", พยากรณ์อากาศจริง, ของแนะนำตามอากาศหนาว/ฝน |
| ปารีสต้อนรับปีใหม่ | อีกประมาณ 2 เดือน | ของแนะนำเรื่องวีซ่าเชงเก้น, แท็บอากาศขึ้นว่าไกลเกินช่วงพยากรณ์ |

### ลำดับเดโมที่แนะนำ

1. หน้าแรก: ดูแถบเตือนสีแดง แล้วแตะ จะเปิดแท็บ **เช็กลิสต์** ของทริปฮอกไกโด
2. ติ๊กของในเช็กลิสต์ (PATCH) > ส่วน "ของแนะนำสำหรับทริปนี้" กด + เพิ่มทีละชิ้น หรือ "เพิ่มทั้งหมด" (POST) > กด × หรือปัดการ์ดเพื่อซ่อน (PATCH /trips)
3. แท็บ **สภาพอากาศ** ดูพยากรณ์รายวัน (Open-Meteo)
4. แท็บ **แผนรายวัน** เพิ่มกิจกรรม (POST) > แตะกิจกรรมเพื่อแก้ (PUT) > ติ๊กทำแล้ว (PATCH) > ลบ (DELETE)
5. แท็บ **ค่าใช้จ่าย** บันทึกรายจ่ายจนเกินงบ ดูแถบเปลี่ยนเป็นสีแดง > ลบรายจ่าย
6. กลับหน้าแรก > ปุ่ม **สร้างทริป** กรอกฟอร์ม (ลองกดสร้างตอนยังไม่กรอก เพื่อดู validator)
7. เมนู ⋮ บนการ์ดทริป > แก้ไขทริป / ลบทริป (มี Dialog ยืนยัน)
8. เมนู **ตั้งค่า** สลับโหมดมืด และเปลี่ยนสกุลเงินหลัก ปิดแอปแล้วเปิดใหม่ ค่ายังอยู่

ทุกครั้งที่บันทึก เปิดไฟล์ `server/db.json` ดูได้ว่าข้อมูลถูกเขียนลงไฟล์จริง

---

## ขั้นที่ 5 รีเซ็ตข้อมูลกลับเป็นค่าเริ่มต้นหลังเดโม

ดับเบิลคลิก **`reset_data.bat`** แล้วกดปุ่มใดก็ได้เพื่อยืนยัน
(หรือรัน `npm run reset` ในโฟลเดอร์ `server`)

- `server/db.json` จะถูกสร้างใหม่จาก `server/db.sample.json` และเลื่อนวันที่ทริปให้ตรงกับวันนี้
  (ทริปฮอกไกโดจะกลับมาเป็น "อีก 2 วัน" เสมอ)
- ถ้า server เปิดอยู่ ไม่ต้องปิดเปิดใหม่ server จะโหลดไฟล์ใหม่เอง
- ในแอปให้ดึงหน้าจอลงเพื่อโหลดใหม่

---

## แก้ปัญหาที่เจอบ่อย

### แอปขึ้นว่า "เชื่อมต่อ server ไม่ได้ กรุณาเปิด server ก่อน"

1. ดูว่าหน้าต่าง server ยังเปิดอยู่และมีคำว่า `Watching...` ถ้าไม่มี ให้ดับเบิลคลิก `start_server.bat` ใหม่
2. เปิด http://localhost:3001/trips ในเบราว์เซอร์ ถ้าไม่ขึ้น JSON แปลว่า server ไม่ได้เปิด
3. เปิด server แล้วกดปุ่ม **ลองใหม่** ในแอป หรือดึงหน้าจอลง
4. บน Android Emulator ข้อความนี้อาจใช้เวลาประมาณ 10 วินาทีกว่าจะขึ้น (แอปรอ server ตามเวลาที่ตั้งไว้ใน `lib/constant/api_config.dart`)

### แท็บสภาพอากาศขึ้นว่า "โหลดพยากรณ์อากาศไม่สำเร็จ"

แท็บนี้เรียก `https://api.open-meteo.com` ผ่านอินเทอร์เน็ต (ไม่ผ่าน server ของเรา)

1. ตรวจว่าคอมพิวเตอร์ต่ออินเทอร์เน็ตได้ แล้วกด **ลองใหม่**
2. ลองเปิด https://api.open-meteo.com/v1/forecast?latitude=13.75&longitude=100.5&daily=temperature_2m_max ในเบราว์เซอร์ ต้องเห็น JSON
3. บน emulator ถ้าเน็ตของ emulator หลุด (ไอคอน Wi-Fi มีเครื่องหมาย !) ให้ปิด emulator แล้วเปิดใหม่ด้วย Cold Boot

ส่วนอื่นของแอปยังใช้ได้ตามปกติแม้โหลดพยากรณ์ไม่ได้ (ของแนะนำส่วนอื่นยังขึ้นครบ)

### port 3001 ถูกใช้อยู่ (server เปิดไม่ขึ้น มีคำว่า `EADDRINUSE`)

มักเกิดจากเปิด server ซ้ำ 2 หน้าต่าง หรือมีโปรแกรมอื่นใช้ port 3001

1. ปิดหน้าต่าง server อื่นที่เปิดค้างไว้ แล้วลองใหม่
2. ถ้ายังไม่หาย หาโปรแกรมที่ใช้ port 3001 แล้วปิด

   ```bat
   netstat -ano | findstr :3001
   taskkill /PID <เลข PID ตัวสุดท้ายของบรรทัด LISTENING> /F
   ```

3. หรือเปลี่ยน port ทั้ง 3 จุดให้ตรงกัน
   - `server/package.json` ในคำสั่ง `start` ตรง `--port 3001`
   - `lib/constant/api_config.dart` ตรง `const int serverPort = 3001;`
   - `run_all.bat` ตรง `set "PORT=3001"`

### บน Chrome ขึ้น error เรื่อง CORS

json-server 0.17.4 ที่ล็อกไว้ใน `server/package.json` เปิด CORS ให้อยู่แล้ว (GET, POST, PUT, PATCH, DELETE ใช้ได้จาก Chrome) และ Open-Meteo ก็อนุญาต CORS
ถ้ายังเจอ ให้ตรวจว่า

1. เปิด server ด้วย `start_server.bat` หรือ `npm start` ในโฟลเดอร์ `server` ไม่ใช่ json-server รุ่นอื่นที่ติดตั้งไว้ทั้งเครื่อง (`npm i -g`)
2. เปิดแอปด้วย `flutter run -d chrome` ไม่ใช่ดับเบิลคลิกไฟล์ html ในโฟลเดอร์ `build`
3. กด F12 ในหน้าต่าง Chrome > แท็บ Console ดูข้อความ error เต็ม

### Emulator เรียก localhost ไม่ได้

ใน Android Emulator คำว่า `localhost` หมายถึงตัว emulator เอง ไม่ใช่คอมพิวเตอร์ของเรา
แอปนี้จัดการให้แล้ว: เมื่อรันบน Android จะเรียก `http://10.0.2.2:3001` ซึ่งเป็นที่อยู่ของคอมพิวเตอร์เมื่อมองจาก emulator
(ตั้งไว้ใน `lib/constant/api_config.dart`) และอนุญาตให้เรียก http แบบไม่เข้ารหัสเฉพาะ `10.0.2.2` และ `localhost` ไว้ใน
`android/app/src/main/res/xml/network_security_config.xml`

ถ้ายังต่อไม่ได้ ให้ลองเปิด `http://10.0.2.2:3001/trips` ใน Chrome **ภายใน emulator** ถ้าเปิดไม่ได้แปลว่า server ไม่ได้เปิดอยู่บนคอมพิวเตอร์

> แอปนี้ตั้งให้ใช้กับ emulator และ Chrome ในเครื่องเดียวกับ server เท่านั้น ถ้าจะใช้มือถือจริงต้องเปลี่ยนที่อยู่ server เป็น IP ของคอมพิวเตอร์ และให้ server รับการเชื่อมต่อจากเครือข่าย ซึ่งไม่ได้ตั้งไว้

### `'npm' is not recognized` หรือ `'flutter' is not recognized`

ยังไม่ได้ติดตั้ง หรือติดตั้งแล้วแต่ยังไม่ได้เปิดหน้าต่าง Command Prompt ใหม่ ให้ปิดแล้วเปิดใหม่ (หรือรีสตาร์ตเครื่อง)

### PowerShell ขึ้นว่า `running scripts is disabled on this system` ตอนพิมพ์ npm

ใช้ Command Prompt (cmd) แทน PowerShell หรือดับเบิลคลิก `start_server.bat`

### `flutter run -d emulator` ขึ้นว่าไม่พบอุปกรณ์

emulator ยังเปิดไม่เสร็จ รอจนเห็นหน้า Home ของ Android แล้วรัน `flutter devices` เช็กอีกครั้ง

### `run_all.bat` ขึ้น "[ผิดพลาด] ..."

อ่านข้อความในหน้าต่างนั้น จะบอกว่าขาดอะไร เช่น ไม่พบ flutter, ไม่พบ Node.js, ไม่พบ Android SDK,
ยังไม่มี emulator (สร้างได้ที่ Android Studio > Device Manager > Create Virtual Device),
port 3001 ถูกโปรแกรมอื่นใช้อยู่ หรือ server เปิดไม่สำเร็จ (ดูข้อความในหน้าต่าง "Travel Planner server")

### build Android ล้ม ขึ้นว่า `Your project's Gradle version (...) is lower than Flutter's minimum supported version`

เกิดเมื่อใช้ Flutter รุ่นใหม่กว่าที่โปรเจกต์ทดสอบไว้ (ทดสอบกับ Flutter 3.32.7) ซึ่งกำหนด Gradle ขั้นต่ำสูงขึ้น
โปรเจกต์นี้ตั้ง Gradle ไว้ที่ **8.14.3** (ใน `android/gradle/wrapper/gradle-wrapper.properties`) และ Android Gradle Plugin ไว้ที่ **8.11.1** (ใน `android/settings.gradle.kts`)
ทดสอบแล้วว่า build ผ่านบน Flutter 3.32.7 และรองรับขั้นต่ำของ Flutter 3.47 ถ้ายังเจอ ให้ `git pull` เอาเวอร์ชันล่าสุด
ข้อความ `Flutter support for your project's Gradle version (8.14.3) will soon be dropped` เป็นแค่คำเตือน ไม่ทำให้ build ล้ม
ถ้า Flutter รุ่นที่ใช้ต้องการ Gradle สูงกว่านี้อีก ให้แก้เลขในไฟล์นั้นตามที่ error แจ้ง แล้วรัน `flutter clean` ก่อน build ใหม่

### build Android ล้ม ขึ้นว่า `Could not find aapt2-...-windows.jar`

เกิดเมื่อเน็ตสะดุดตอน Gradle ดาวน์โหลดเครื่องมือของ Android ครั้งแรก แล้ว Gradle จำผล "หาไม่เจอ" ไว้ ให้บังคับโหลดใหม่

```bat
cd android
gradlew --refresh-dependencies
cd ..
flutter run -d emulator
```

### build Android ล้ม ขึ้นว่า `Gradle build failed due to Java/Gradle incompatibility`

เช่น `The Java version used for the build is 25.0.2, which is incompatible with Gradle 8.12`

สาเหตุ: Flutter ในเครื่องเลือกใช้ Java ที่ใหม่เกินไป (เช่น Java 25) แต่ Gradle 8.x ของโปรเจกต์นี้ใช้ Java รุ่นนั้นไม่ได้ โปรเจกต์นี้ทดสอบกับ **Java 17-23** (เครื่องที่ใช้ทดสอบใช้ Java 21)
มักเกิดกับเครื่องที่ติดตั้ง JDK รุ่นล่าสุดไว้ และตั้ง `JAVA_HOME` ชี้ไปที่ JDK ตัวนั้น

- ถ้าใช้ `run_all.bat` สคริปต์จะตรวจให้เองก่อน build โดยรัน `java -version` ของ Java ตัวที่ Flutter ใช้จริง ถ้าใช้ไม่ได้ จะค้นหา JDK 17-23 ที่ติดตั้งอยู่ในเครื่อง (Java ของ Android Studio, Temurin, Oracle, Microsoft, Zulu, Corretto) แล้วถามว่าให้ใช้ตัวนั้นไหม กด `Y` แล้วรอ build ต่อได้เลย
- ถ้าในเครื่องไม่มี JDK ที่ใช้ได้เลย (เช่น Android Studio รุ่นใหม่ที่มากับ Java 25) ให้ติดตั้ง JDK 21 ด้วยคำสั่ง `winget install EclipseAdoptium.Temurin.21.JDK` แล้วดับเบิลคลิก `run_all.bat` ใหม่ สคริปต์จะหาเจอและถามให้ใช้เอง
- ถ้าจะแก้เอง ให้บอก Flutter ให้ใช้ Java ที่มากับ Android Studio แล้วเช็กผล

  ```bat
  flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
  cd android
  gradlew --stop
  cd ..
  flutter doctor -v
  ```

  ใน `flutter doctor -v` บรรทัด `Java version` ต้องเป็น 17 ถึง 21 (เช่น `build 21.0.8`) จากนั้นรัน `flutter run -d emulator` ใหม่
- ถ้าไม่มี Android Studio ให้ติดตั้ง JDK 17 หรือ 21 (เช่น Eclipse Temurin) แล้วใช้คำสั่ง `flutter config --jdk-dir="โฟลเดอร์ของ JDK นั้น"` แทน

### build Android ขึ้นคำเตือนเรื่อง Android NDK

ข้อความ `Your project is configured with Android NDK ... shared_preferences_android requires Android NDK ...` เป็นแค่คำเตือน
ถ้าตามด้วย `√ Built build\app\outputs\flutter-apk\app-debug.apk` แปลว่า build สำเร็จ ไม่ต้องแก้อะไร

### build Android ขึ้นข้อความยาว ๆ `Could not close incremental caches ... different roots`

เกิดเมื่อโปรเจกต์อยู่คนละไดรฟ์กับ Flutter pub cache (เช่น โปรเจกต์อยู่ไดรฟ์ D: แต่ cache อยู่ไดรฟ์ C:)
เป็นแค่คำเตือนของ Kotlin ถ้าตามด้วย `√ Built build\app\outputs\flutter-apk\app-debug.apk` แปลว่า build สำเร็จ ไม่ต้องแก้อะไร

### build Android ครั้งแรกล้มเพราะ Gradle หรือหน่วยความจำไม่พอ

ปิดโปรแกรมที่ใช้ RAM มาก ๆ ก่อน แล้วลองปิด Gradle ที่ค้างอยู่และ build ใหม่

```bat
cd android
gradlew --stop
cd ..
flutter clean
flutter pub get
flutter run -d emulator
```
