@TITLE Selenium-Grid
@ECHO off
color 0a
ECHO ***************************************
ECHO        Stop last Java instance
ECHO ***************************************
taskkill /f /im java.exe

ECHO.
ECHO.
ECHO ***************************************
ECHO           Loading Variables
ECHO ***************************************
:: define the root directory & path
SETLOCAL
SET DRIVEPATH=%~d0
SET SCRIPTPATH=%~dp0
echo DrivePath = %DRIVEPATH%
echo ScriptPath = %SCRIPTPATH%

:: define git & java path
SET PATH=%PATH%;%SCRIPTPATH%\java\bin;%DRIVEPATH%\git\bin
java -version
git --version

:: define selenium server jar path
SET SERVERPATH="%SCRIPTPATH%src\main\resources\selenium-server-standalone.jar"
echo ServerPath = %SERVERPATH%

:: define browser driver paths
SET CHROMEDRIVER=-Dwebdriver.chrome.driver="%SCRIPTPATH%src\main\resources\org\nwea\selenium\driver\windows\googlechrome\32bit\chromedriver.exe"
echo ChromeDriverPath = %CHROMEDRIVER%

:: define variable, else script throws an error.
SET HUB_IP=""

GOTO SWITCH

:HUB
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO        Starting Selenium Hub
    ECHO ***************************************
    FOR /F "tokens=2,3" %%A IN ('ping %computername% -n 1 -4') DO IF "from"== "%%A" set "IP=%%~B"
    ECHO Your IP Address is: %IP:~0,-1%
    ECHO.
    java -jar %SERVERPATH% -role hub %HUBJSONPATH% -maxSession 5 -browserTimeout 0 -cleanUpCycle 5000 -timeout 300
    GOTO MENU

:NODE_DEFAULT
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO        Starting Selenium Node
    ECHO ***************************************
    IF "%~2"=="" (
        SET VERSION="3.4.0"
    ) ELSE (
        SET VERSION="%2"
    )
    IF %HUB_IP%=="" (
        IF "%~3"=="" (
            SET HUB_IP="10.125.0.76"
        ) ELSE (
            SET HUB_IP="%3"
        )
    )
    SET CHROME=-browser browserName=chrome,setjavascriptEnabled=true,acceptSslCerts=true,version=%VERSION%,maxInstances=1,applicationName=%COMPUTERNAME%
    java %CHROMEDRIVER% -jar %SERVERPATH% -role webdriver -timeout 60000 -browserTimeout 60000 -maxSession 1 -port 5554 -hub http://%HUB_IP%:4444/grid/register %CHROME%
    GOTO MENU

:NODE_HUB_IP
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO        Setup Selenium Node
    ECHO ***************************************
    ECHO.
    SET /P HUB_IP="Enter the Hub IP: "
    ECHO.
    GOTO NODE_DEFAULT

:GIT_UPDATE
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO              Git Update
    ECHO ***************************************
    ECHO.
    cd %SCRIPTPATH%
    git fetch origin master
    git reset --hard FETCH_HEAD
    git clean -f -d
    :: -f -d Remove untracked files and untracked directories from the current directory.

:CLEAN_TEMP
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO Cleaning Temp folders...
    ECHO ***************************************
    cd %temp%
    for /d %%D in (*) do rd /s /q "%%D"
    del /f /q *
    cd C:\temp
    for /d %%D in (*) do rd /s /q "%%D"
    del /f /q *
    ECHO.
    ECHO.

:EXIT
    GOTO :EOF

:INSTALL
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO        Install Drivers Locally
    ECHO ***************************************
    :: setup schedule task to start selenium node
    SchTasks /Create /SC DAILY /TN "start-selenium-node1" /TR "C:\dev\source\start-selenium-node.bat" /ST 07:00
    SchTasks /Create /SC ONLOGON /TN "start-selenium-node2" /TR "C:\dev\source\start-selenium-node.bat"

    :: clone the selenium driver repo
    mkdir C:\dev\source\
    git clone http://stash.americas.nwea.pvt/scm/sel/selenium-drivers.git C:\dev\source\selenium-drivers

    :: make selenium node batch file that runs locally
    SET /P GROUP="Enter group identifier(i.e. VM or LAB): "
    ECHO.
    @ECHO OFF
    (CALL C:\dev\source\selenium-drivers\selenium-menu.bat 4) > C:\dev\source\start-selenium-node.bat
    (CALL C:\dev\source\selenium-drivers\selenium-menu.bat 5) >> C:\dev\source\start-selenium-node.bat
    (CALL C:\dev\source\selenium-drivers\selenium-menu.bat 2 %GROUP%) >> C:\dev\source\start-selenium-node.bat
    PING 192.0.2.2 -n 1 -w 10000 > nul
    GOTO :EOF

:MENU
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO            Selenium Grid
    ECHO ***************************************
    ECHO.
    ECHO    1 - Hub
    ECHO    2 - Node (default hub)
    ECHO    3 - Node (specify hub ip address)
    ECHO    4 - Git Update (from stash)
    ECHO    5 - Clean Temp
    ECHO    6 - Exit
    ECHO.
    SET /P M="Type 1, 2, 3 or 4 then press ENTER: "
    ECHO.
    ECHO %M%
    IF %M%==1 GOTO HUB
    IF %M%==2 GOTO NODE_DEFAULT
    IF %M%==3 GOTO NODE_HUB_IP
    IF %M%==4 GOTO GIT_UPDATE
    IF %M%==5 GOTO CLEAN_TEMP
    IF %M%==6 GOTO EXIT

:SWITCH
    ECHO.
    ECHO.
    ECHO ***************************************
    ECHO          Command Line Switch
    ECHO ***************************************
    ECHO command switch = %1
    IF "%~1"=="" GOTO MENU
    IF "%~1"=="1" GOTO HUB
    IF "%~1"=="2" GOTO NODE_DEFAULT
    IF "%~1"=="3" GOTO NODE_HUB_IP
    IF "%~1"=="4" GOTO GIT_UPDATE
    IF "%~1"=="5" GOTO CLEAN_TEMP
