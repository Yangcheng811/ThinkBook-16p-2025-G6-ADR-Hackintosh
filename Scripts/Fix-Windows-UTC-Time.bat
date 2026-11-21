@echo off
chcp 65001 >nul
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please right-click and "Run as administrator"!
    echo 请右键以【管理员身份运行】此文件！
    pause
    exit /b 1
)

echo Setting Windows hardware clock (RTC) to UTC (RealTimeIsUniversal = 1)...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f

echo Syncing Windows time now...
sc config w32time start= auto >nul 2>&1
net start w32time >nul 2>&1
w32tm /resync /force

echo.
echo Done! Both Windows and macOS will now use UTC for hardware clock (no more 8-hour jump).
echo 完成！现在 Windows 和 macOS 统一使用 UTC 硬件时钟，双系统切换不再倒退 8 小时。
echo.
pause
