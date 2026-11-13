@echo off
chcp 65001 >nul
title Travel Planner - run APK
rem ===== ดับเบิลคลิกครั้งเดียว: เปิด server + เปิด Android Emulator + ติดตั้งแอปจากไฟล์ APK แล้วเปิดแอป =====
rem ใช้ไฟล์ dist\TravelPlanner.apk ที่ build ไว้แล้ว จึงไม่ต้องมี Flutter / Java / Gradle ในเครื่อง
rem ต้องมีแค่ Node.js (สำหรับ server) และ Android Studio (สำหรับ Android SDK + emulator)
rem 1) เปิด server ในหน้าต่างแยก (ถ้ายังไม่ได้เปิด)
rem 2) เปิด emulator ตัวแรกที่มีในเครื่อง (ถ้ายังไม่ได้เปิด) แล้วรอจน boot เสร็จ
rem 3) adb install แล้วเปิดแอป

cd /d "%~dp0"
set "PORT=3001"
set "APK=%~dp0dist\TravelPlanner.apk"
set "PKG=com.example.travel_planner"
if not exist "%APK%" goto no_apk

rem ---------- ตรวจโปรแกรมที่ต้องใช้ ----------
where node >nul 2>nul
if errorlevel 1 goto no_node

rem ---------- หาที่อยู่ Android SDK ----------
set "SDK=%LOCALAPPDATA%\Android\Sdk"
if defined ANDROID_SDK_ROOT set "SDK=%ANDROID_SDK_ROOT%"
if defined ANDROID_HOME set "SDK=%ANDROID_HOME%"
set "ADB=%SDK%\platform-tools\adb.exe"
set "EMU=%SDK%\emulator\emulator.exe"
if not exist "%ADB%" goto no_sdk
if not exist "%EMU%" goto no_sdk

rem ---------- 1) server ----------
echo [1/3] ตรวจ server ...
call :check_server
if "%CODE%"=="200" goto server_ok
rem port ตอบกลับ แต่ไม่มี /trips = เป็นโปรแกรมอื่น ไม่ใช่ server ของแอปนี้
if not "%CODE%"=="000" goto port_busy
echo       ยังไม่ได้เปิด กำลังเปิด server ในหน้าต่างใหม่ [ห้ามปิดหน้าต่างนั้น]
start "Travel Planner server" cmd /c call "%~dp0start_server.bat"
set /a TRIES=0
:wait_server
call :check_server
if "%CODE%"=="200" goto server_ok
set /a TRIES+=1
if %TRIES% geq 120 goto server_fail
ping -n 2 127.0.0.1 >nul
goto wait_server
:server_ok
echo       server พร้อมที่ http://localhost:%PORT%

rem ---------- 2) emulator ----------
echo [2/3] ตรวจ Android Emulator ...
"%ADB%" start-server >nul 2>nul
"%ADB%" devices | findstr /b "emulator-" >nul
if not errorlevel 1 goto wait_boot
set "AVD="
for /f "delims=" %%a in ('call "%EMU%" -list-avds 2^>nul') do if not defined AVD set "AVD=%%a"
if not defined AVD goto no_avd
echo       กำลังเปิด emulator %AVD% ...
start "" "%EMU%" -avd %AVD%
:wait_boot
echo       รอ emulator boot ให้เสร็จ [ครั้งแรกอาจใช้ 1-3 นาที] ...
"%ADB%" wait-for-device
set /a TRIES=0
:wait_boot_loop
"%ADB%" shell getprop sys.boot_completed 2>nul | findstr "1" >nul
if not errorlevel 1 goto boot_ok
set /a TRIES+=1
if %TRIES% geq 180 goto boot_fail
ping -n 2 127.0.0.1 >nul
goto wait_boot_loop
:boot_ok
echo       emulator พร้อมแล้ว

rem ---------- 3) ติดตั้ง APK แล้วเปิดแอป ----------
echo [3/3] ติดตั้งแอปจากไฟล์ %APK% ...
set "ILOG=%TEMP%\travel_planner_install.log"
"%ADB%" install -r "%APK%" > "%ILOG%" 2>&1
type "%ILOG%"
findstr /c:"Success" "%ILOG%" >nul
if not errorlevel 1 goto installed
rem ลายเซ็นไม่ตรงกับแอปเดิมในเครื่อง (เช่น เคยติดตั้งแอปที่ build จากเครื่องอื่น) ให้ลบแอปเดิมแล้วติดตั้งใหม่
findstr /c:"INSTALL_FAILED_UPDATE_INCOMPATIBLE" "%ILOG%" >nul
if errorlevel 1 goto install_fail
echo       พบแอปเดิมที่ลายเซ็นไม่ตรง กำลังลบแอปเดิมแล้วติดตั้งใหม่ ...
"%ADB%" uninstall %PKG% >nul
"%ADB%" install "%APK%" > "%ILOG%" 2>&1
type "%ILOG%"
findstr /c:"Success" "%ILOG%" >nul
if errorlevel 1 goto install_fail
:installed
echo       ติดตั้งเรียบร้อย กำลังเปิดแอป ...
"%ADB%" shell am start -n %PKG%/.MainActivity >nul
if errorlevel 1 goto launch_fail
echo.
echo เปิดแอป Travel Planner บน emulator แล้ว
echo - ใช้งานแอปได้เลย ห้ามปิดหน้าต่าง "Travel Planner server" ระหว่างใช้แอป
echo - เลิกใช้: ปิดหน้าต่าง server และปิด emulator (ดู HOW_TO_RUN.md หัวข้อ "ปิดทุกอย่าง")
echo - ถ้าแอปขึ้นว่าเชื่อมต่อ server ไม่ได้ ให้เปิด server แล้วกดปุ่ม "ลองใหม่" ในแอป
pause
exit /b 0

rem ---------- ฟังก์ชันตรวจ server: CODE = 200 (server ของแอปนี้), 000 (ยังไม่มีใครใช้ port), อื่น ๆ (โปรแกรมอื่น) ----------
:check_server
set "CODE=000"
for /f %%c in ('curl.exe -s -o nul -m 3 -w "%%{http_code}" http://127.0.0.1:%PORT%/trips 2^>nul') do set "CODE=%%c"
exit /b 0

rem ---------- ข้อความผิดพลาด ----------
:no_node
echo [ผิดพลาด] ไม่พบ Node.js กรุณาติดตั้งจาก https://nodejs.org
pause
exit /b 1
:no_sdk
echo [ผิดพลาด] ไม่พบ Android SDK ที่ %SDK%
echo กรุณาติดตั้ง Android Studio หรือตั้งค่า ANDROID_HOME ให้ชี้ไปที่ Android SDK
pause
exit /b 1
:no_avd
echo [ผิดพลาด] ยังไม่มี emulator ในเครื่อง สร้างได้ที่ Android Studio ^> Device Manager ^> Create Virtual Device
pause
exit /b 1
:no_apk
echo [ผิดพลาด] ไม่พบไฟล์ %APK%
echo ไฟล์นี้อยู่ใน repo แล้ว ลอง git pull ใหม่ หรือดาวน์โหลด repo ใหม่ทั้งโฟลเดอร์
pause
exit /b 1
:install_fail
echo.
echo [ผิดพลาด] ติดตั้ง APK ไม่สำเร็จ (ดูข้อความด้านบน)
echo - ลองลบแอปเดิมด้วยคำสั่ง  "%ADB%" uninstall %PKG%  แล้วดับเบิลคลิก run_apk.bat ใหม่
echo - ถ้าขึ้น INSUFFICIENT_STORAGE: พื้นที่ใน emulator ไม่พอ ลบแอปอื่นหรือ Wipe Data ใน Device Manager
pause
exit /b 1
:launch_fail
echo [ผิดพลาด] ติดตั้งแล้วแต่เปิดแอปไม่สำเร็จ ให้เปิดแอป "Travel Planner" จากหน้ารวมแอปใน emulator เอง
pause
exit /b 1
:port_busy
echo [ผิดพลาด] port %PORT% ถูกโปรแกรมอื่นใช้อยู่ (ตอบกลับรหัส %CODE% ไม่ใช่ server ของแอปนี้)
echo กรุณาปิดหน้าต่าง server ของแอปอื่นที่ใช้ port %PORT% แล้วดับเบิลคลิกไฟล์นี้ใหม่
echo ดูโปรแกรมที่ใช้ port ได้ด้วยคำสั่ง: netstat -ano ^| findstr :%PORT%
pause
exit /b 1
:server_fail
echo [ผิดพลาด] เปิด server ไม่สำเร็จภายใน 2 นาที ดูข้อความในหน้าต่าง "Travel Planner server"
pause
exit /b 1
:boot_fail
echo [ผิดพลาด] emulator boot ไม่เสร็จภายใน 3 นาที ลองเปิดจาก Android Studio ^> Device Manager แล้วรันไฟล์นี้ใหม่
pause
exit /b 1
