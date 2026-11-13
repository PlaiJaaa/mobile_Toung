// สร้าง db.json ใหม่จากข้อมูลตัวอย่าง db.sample.json
// วันที่ในข้อมูลตัวอย่างอ้างอิงวันที่ 13 พ.ย. 2026 (ANCHOR)
// สคริปต์นี้จะเลื่อนวันที่ของทริปและรายจ่ายให้ตรงกับ "วันนี้" ทุกครั้งที่รีเซ็ต
// เพื่อให้เดโมวันไหนก็ได้ผลเหมือนเดิม: ทริปที่ไปแล้ว / ทริปที่จะไปในอีก 2 วัน / ทริปที่ไปอีกนาน
//
// ใช้งาน: node reset_db.js          -> เขียนทับ db.json เสมอ
//         node reset_db.js --if-missing -> สร้างเฉพาะตอนที่ยังไม่มี db.json

const fs = require('fs');
const path = require('path');

const ANCHOR = '2026-11-13';
const samplePath = path.join(__dirname, 'db.sample.json');
const dbPath = path.join(__dirname, 'db.json');

if (process.argv.includes('--if-missing') && fs.existsSync(dbPath)) {
  process.exit(0);
}

// จำนวนวันระหว่างวันอ้างอิงกับวันนี้ (ตามเวลาเครื่อง)
const now = new Date();
const todayUtc = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
const anchorUtc = Date.parse(ANCHOR + 'T00:00:00Z');
const shiftDays = Math.round((todayUtc - anchorUtc) / 86400000);

// เลื่อนวันที่รูปแบบ yyyy-MM-dd ไป shiftDays วัน
function shift(dateText) {
  const time = Date.parse(dateText + 'T00:00:00Z') + shiftDays * 86400000;
  return new Date(time).toISOString().slice(0, 10);
}

const db = JSON.parse(fs.readFileSync(samplePath, 'utf8'));
for (const trip of db.trips) {
  trip.startDate = shift(trip.startDate);
  trip.endDate = shift(trip.endDate);
}
for (const expense of db.expenses) {
  expense.date = shift(expense.date);
}

fs.writeFileSync(dbPath, JSON.stringify(db, null, 2) + '\n', 'utf8');
console.log(
  'สร้าง db.json จาก db.sample.json แล้ว (เลื่อนวันที่ ' + shiftDays + ' วันให้ตรงกับวันนี้)'
);
