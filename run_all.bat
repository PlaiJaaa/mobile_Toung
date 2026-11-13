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
echo       ตรวจเวอร์ชัน Java ที่ Flutter ใช้ ...
set "JMAJOR="
for /f "tokens=*" %%l in ('flutter doctor -v 2^>nul ^| findstr /c:"Java version"') do if not defined JMAJOR (set "JLINE=%%l" & call :parse_java)
if not defined JMAJOR goto java_ok
if %JMAJOR% lss 17 goto java_bad
if %JMAJOR% gtr 23 goto java_bad
:java_ok
if defined JMAJOR echo       Java %JMAJOR% ใช้ได้

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

rem ---------- ฟังก์ชันอ่านเลขเวอร์ชันหลักของ Java จากบรรทัด "Java version ... (build 21.0.8+...)" ----------
:parse_java
rem ตัดทุกอย่างจนถึง "(build " ออก จะเหลือ เช่น 21.0.8+-14196175...
set "JBUILD=%JLINE:*(build =%"
if "%JBUILD%"=="%JLINE%" exit /b 0
for /f "tokens=1 delims=.+- " %%b in ("%JBUILD%") do set "JMAJOR=%%b"
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
:java_bad
echo.
echo [ผิดพลาด] Flutter ใช้ Java %JMAJOR% ในการ build Android แต่โปรเจกต์นี้ต้องใช้ Java 17-23
echo           (ถ้าใช้ Java 24 ขึ้นไป จะ build ไม่ผ่านและขึ้นว่า Java/Gradle incompatibility)
set "ASJBR=%ProgramFiles%\Android\Android Studio\jbr"
if not exist "%ASJBR%\bin\java.exe" goto java_manual
echo.
echo พบ Java ที่มากับ Android Studio: %ASJBR%
choice /c YN /m "ให้ Flutter ใช้ Java ตัวนี้เลยไหม"
if errorlevel 2 goto java_manual
call flutter config --jdk-dir="%ASJBR%"
if exist "android\gradlew.bat" (pushd android & call gradlew.bat --stop >nul 2>nul & popd)
echo ตั้งค่าเรียบร้อย กำลังรันต่อ ...
set "JMAJOR="
goto java_ok
:java_manual
echo.
echo วิธีแก้: ติดตั้ง JDK 17 หรือ 21 (หรือ Android Studio ซึ่งมี Java 21 มาให้) แล้วรันคำสั่ง
echo     flutter config --jdk-dir="ที่อยู่โฟลเดอร์ JDK"
echo เช่น flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
echo จากนั้นดับเบิลคลิก run_all.bat ใหม่ (ดูรายละเอียดใน HOW_TO_RUN.md หัวข้อ Java/Gradle incompatibility)
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
