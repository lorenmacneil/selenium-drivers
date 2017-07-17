SET SCRIPTPATH=%~dp0
cd %SCRIPTPATH%
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
copy %SCRIPTPATH%start-selenium-node.bat C:\dev\source\
ping 192.0.2.2 -n 1 -w 10000 > nul