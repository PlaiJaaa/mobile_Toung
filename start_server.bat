@echo off
chcp 65001 >nul
title Travel Planner server (json-server :3001)
rem ===== เปิด REST API ของแอป Travel Planner (json-server) =====
rem ดับเบิลคลิกไฟล์นี้ได้เลย ปิดหน้าต่างนี้ = ปิด server

cd /d "%~dp0server"

where node >nul 2>nul
if errorlevel 1 (
  echo [ผิดพลาด] ไม่พบ Node.js กรุณาติดตั้งจาก https://nodejs.org แล้วเปิดไฟล์นี้ใหม่
  pause
  exit /b 1
)

if not exist "node_modules\json-server" (
  echo กำลังติดตั้ง package ของ server ครั้งแรก [npm install] ...
  call npm install --no-audit --no-fund
  if errorlevel 1 (
    echo [ผิดพลาด] ติดตั้ง package ไม่สำเร็จ ตรวจการเชื่อมต่ออินเทอร์เน็ตแล้วลองใหม่
    pause
    exit /b 1
  )
)

echo.
echo เปิด server ที่ http://localhost:3001  [ลองเปิด http://localhost:3001/trips ในเบราว์เซอร์]
echo ปิด server: กด Ctrl+C หรือปิดหน้าต่างนี้
echo.
call npm start

echo.
echo server หยุดทำงานแล้ว (ถ้ามีข้อความ error ด้านบน เช่น port 3001 ถูกใช้อยู่ ดูวิธีแก้ใน HOW_TO_RUN.md)
pause
