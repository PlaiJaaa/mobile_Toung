@echo off
chcp 65001 >nul
title Travel Planner - run all
rem ===== ดับเบิลคลิกครั้งเดียว: เปิด server + เปิด Android Emulator + รันแอป =====
rem 1) เปิด server ในหน้าต่างแยก (ถ้ายังไม่ได้เปิด)
rem 2) เปิด emulator ตัวแรกที่มีในเครื่อง (ถ้ายังไม่ได้เปิด) แล้วรอจน boot เสร็จ
rem 3) flutter run -d emulator
rem แอปนี้ใช้ port 3001 จึงเปิดพร้อมกับแอปอื่นที่ใช้ port 3000 (เช่น แอปหอพัก) ได้

cd /d "%~dp0"
set "PORT=3001"

rem ---------- ตรวจโปรแกรมที่ต้องใช้ ----------
where flutter >nul 2>nul
if errorlevel 1 goto no_flutter
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

rem ---------- ตรวจ Java ที่ Flutter ใช้ build Android ----------
rem Gradle 8.12 ของโปรเจกต์นี้ใช้ได้กับ Java 17-23 เท่านั้น (Java 24 ขึ้นไป build ไม่ผ่าน)
rem หา java ที่ Flutter ใช้ (บรรทัด "Java binary at:" ใน flutter doctor) ถ้าไม่มีดู JAVA_HOME แล้วค่อยดู PATH
rem แล้วรัน java -version เองเพื่ออ่านเวอร์ชัน
echo       ตรวจเวอร์ชัน Java ที่ Flutter ใช้ [ใช้เวลาประมาณ 10-30 วินาที] ...
set "FJAVA="
set "JLINE="
for /f "tokens=*" %%l in ('flutter doctor -v 2^>nul ^| findstr /c:"Java binary at:"') do if not defined JLINE set "JLINE=%%l"
if defined JLINE set "FJAVA=%JLINE:*Java binary at: =%"
if not defined FJAVA if defined JAVA_HOME set "FJAVA=%JAVA_HOME%\bin\java"
if not defined FJAVA for /f "delims=" %%j in ('where java 2^>nul') do if not defined FJAVA set "FJAVA=%%j"
if not defined FJAVA goto java_missing
call :java_major "%FJAVA%"
if not defined JV goto java_missing
if %JV% lss 17 goto java_bad
if %JV% gtr 23 goto java_bad
echo       Java %JV% ใช้ได้ [%FJAVA%]
:java_ok

rem ---------- 3) รันแอป ----------
echo [3/3] รันแอปบน emulator [ครั้งแรก build 2-5 นาที]
echo       ระหว่างรัน: กด r = hot reload, R = hot restart, q = ปิดแอป
call flutter pub get
call flutter run -d emulator
echo.
echo แอปหยุดทำงานแล้ว (server ยังเปิดอยู่ในอีกหน้าต่าง ปิดหน้าต่างนั้นเพื่อปิด server)
pause
exit /b 0

rem ---------- ฟังก์ชันตรวจ server: CODE = 200 (server ของแอปนี้), 000 (ยังไม่มีใครใช้ port), อื่น ๆ (โปรแกรมอื่น) ----------
:check_server
set "CODE=000"
for /f %%c in ('curl.exe -s -o nul -m 3 -w "%%{http_code}" http://127.0.0.1:%PORT%/trips 2^>nul') do set "CODE=%%c"
exit /b 0

rem ---------- ฟังก์ชันอ่านเลขเวอร์ชันหลักของ java ที่ส่งมา: JV = 21, 25, ... (อ่านไม่ได้ = ว่าง) ----------
rem java -version พิมพ์ เช่น  openjdk version "21.0.8" 2025-07-15  หรือ  java version "25.0.2" 2026-01-20 LTS
:java_major
set "JV="
set "JVS="
for /f "tokens=3" %%v in ('call "%~1" -version 2^>^&1 ^| findstr /i /c:" version "') do if not defined JVS set "JVS=%%~v"
if not defined JVS exit /b 0
for /f "tokens=1,2 delims=." %%a in ("%JVS%") do (
  set "JV=%%a"
  if "%%a"=="1" set "JV=%%b"
)
exit /b 0

rem ---------- ฟังก์ชันลองโฟลเดอร์ JDK: ถ้าเป็น Java 17-23 จำไว้ใน GOODJDK ----------
:try_jdk
if defined GOODJDK exit /b 0
if not exist "%~1\bin\java.exe" exit /b 0
call :java_major "%~1\bin\java.exe"
if not defined JV exit /b 0
if %JV% lss 17 exit /b 0
if %JV% gtr 23 exit /b 0
set "GOODJDK=%~1"
set "GOODV=%JV%"
exit /b 0

rem ---------- ข้อความผิดพลาด ----------
:no_flutter
echo [ผิดพลาด] ไม่พบคำสั่ง flutter กรุณาติดตั้ง Flutter และเพิ่มลง PATH ดู HOW_TO_RUN.md ขั้นที่ 1
pause
exit /b 1
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
:java_missing
echo.
echo [ผิดพลาด] หา Java ที่ Flutter ใช้ build Android ไม่เจอ หรือเรียกใช้ไม่ได้
goto java_search
:java_bad
echo.
echo [ผิดพลาด] Flutter ใช้ Java %JV% ในการ build Android [%FJAVA%]
echo           แต่โปรเจกต์นี้ต้องใช้ Java 17-23 (Java 24 ขึ้นไปจะขึ้นว่า Java/Gradle incompatibility)
:java_search
echo กำลังค้นหา JDK 17-23 ที่ติดตั้งอยู่ในเครื่อง ...
set "GOODJDK="
set "GOODV="
call :try_jdk "%ProgramFiles%\Android\Android Studio\jbr"
call :try_jdk "%LOCALAPPDATA%\Programs\Android Studio\jbr"
for /d %%d in ("%ProgramFiles%\Eclipse Adoptium\jdk-*" "%ProgramFiles%\Microsoft\jdk-*" "%ProgramFiles%\Java\jdk*" "%ProgramFiles%\Zulu\zulu*" "%ProgramFiles%\Amazon Corretto\jdk*") do call :try_jdk "%%~d"
if not defined GOODJDK goto java_manual
echo.
echo พบ Java %GOODV% ที่ใช้ได้: %GOODJDK%
choice /c YN /m "ให้ Flutter ใช้ Java ตัวนี้เลยไหม"
if errorlevel 2 goto java_manual
call flutter config --jdk-dir="%GOODJDK%"
if exist "android\gradlew.bat" (pushd android & call gradlew.bat --stop >nul 2>nul & popd)
echo ตั้งค่าเรียบร้อย กำลังรันต่อ ...
goto java_ok
:java_manual
echo.
echo วิธีแก้:
echo   1) ติดตั้ง JDK 21 ด้วยคำสั่งนี้ใน cmd:  winget install EclipseAdoptium.Temurin.21.JDK
echo      (หรือดาวน์โหลดตัวติดตั้งจาก https://adoptium.net)
echo   2) ปิดหน้าต่างนี้ แล้วดับเบิลคลิก run_all.bat ใหม่ สคริปต์จะหา JDK 21 เจอและถามให้ใช้เอง
echo   หรือตั้งเอง: flutter config --jdk-dir="โฟลเดอร์ของ JDK 17-21"
echo ดูรายละเอียดใน HOW_TO_RUN.md หัวข้อ Java/Gradle incompatibility
pause
exit /b 1
:port_busy
echo [ผิดพลาด] port %PORT% ถูกโปรแกรมอื่นใช้อยู่ (ตอบกลับรหัส %CODE% ไม่ใช่ server ของแอปนี้)
echo กรุณาปิดหน้าต่าง server ของแอปอื่นที่ใช้ port %PORT% แล้วดับเบิลคลิก run_all.bat ใหม่
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
