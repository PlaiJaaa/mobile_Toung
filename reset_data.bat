@echo off
chcp 65001 >nul
rem ===== รีเซ็ตข้อมูลของ server กลับเป็นข้อมูลตัวอย่าง =====
rem สร้าง server\db.json ใหม่จาก server\db.sample.json และเลื่อนวันที่ทริปให้ตรงกับวันนี้

cd /d "%~dp0server"

where node >nul 2>nul
if errorlevel 1 (
  echo [ผิดพลาด] ไม่พบ Node.js กรุณาติดตั้งจาก https://nodejs.org
  pause
  exit /b 1
)

echo ข้อมูลทั้งหมดที่เพิ่มหรือแก้ระหว่างเดโม (ทริป กิจกรรม รายจ่าย เช็กลิสต์) จะถูกแทนที่ด้วยข้อมูลตัวอย่าง
echo กดปุ่มใดก็ได้เพื่อรีเซ็ต หรือปิดหน้าต่างนี้เพื่อยกเลิก
pause >nul

node reset_db.js
if errorlevel 1 (
  echo [ผิดพลาด] รีเซ็ตไม่สำเร็จ
  pause
  exit /b 1
)

echo รีเซ็ตข้อมูลเรียบร้อย
echo - ถ้า server เปิดอยู่ server จะโหลดข้อมูลใหม่เอง ไม่ต้องปิดเปิดใหม่
echo - ในแอปให้ดึงหน้าจอลงเพื่อโหลดใหม่
pause
