#!/bin/bash

echo
echo
echo "***************************************"
echo        "Loading variables"
echo "***************************************"

# fetch host name
HOST=$(hostname)

# remove .local from host name
MOD=${HOST%%.*}
echo Host= $HOST

# change dash to underscore "-" to "_"
COMPUTERNAME=${MOD//[-]/_}
echo ComputerName= $COMPUTERNAME

# define the root directory & path
DRIVEPATH=$(dirname $(dirname $0))
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DRIVEPATH
echo $SCRIPTPATH

# define selenium server jar path
SERVERPATH="$SCRIPTPATH/src/main/resources/selenium-server-standalone.jar"
echo ServerPath= $SERVERPATH

# define browser driver paths
CHROMEDRIVER=-Dwebdriver.chrome.driver="$SCRIPTPATH/src/main/resources/org/nwea/selenium/driver/osx/googlechrome/64bit/chromedriver"
echo $CHROMEDRIVER

# define what group identifier to use
if ["$2" -eq ""]
then
    VERSION="3.6.0"
else
    VERSION="$2"
fi
echo $VERSION

# define browsers and capabilities
FIREFOX="-browser browserName=firefox,setjavascriptEnabled=true,acceptSslCerts=true,version=$VERSION,maxInstances=1,applicationName=$COMPUTERNAME"
SAFARI="-browser browserName=safari,setjavascriptEnabled=true,acceptSslCerts=true,version=$VERSION,maxInstances=1,applicationName=$COMPUTERNAME"
CHROME="-browser browserName=chrome,setjavascriptEnabled=true,acceptSslCerts=true,version=$VERSION,maxInstances=1,applicationName=$COMPUTERNAME"


KILL_JAVA () {
    echo "***************************************"
    echo       "Stop last instance of Java"
    echo "***************************************"
    killall java
}

HUB () {
    echo
    echo
    echo "***************************************"
    echo           "Start Selenium Hub"
    echo "***************************************"
    echo Your IP Address is:
    ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
    echo
    java -jar "$SERVERPATH" -role hub $HUBJSONPATH -maxSession 4 -browserTimeout 0 -cleanUpCycle 5000 -timeout 300
}

NODE_DEFAULT () {
    echo
    echo
    echo "***************************************"
    echo           "Start Selenium Node"
    echo "***************************************"
    # HUB_IP=webmap.americas.nwea.pvt
    HUB_IP=10.125.0.29
    NODE
}

NODE_HUB_IP () {
    echo
    echo
    echo "***************************************"
    echo           "Start Selenium Node"
    echo "***************************************"
    echo
    echo -n "Enter the Hub IP: "
    read choice
    HUB_IP=$choice
    NODE
}

NODE () {
    java $CHROMEDRIVER -jar "$SERVERPATH" -browserTimeout 60000 -maxSession 1 -role webdriver -port 5554 -hub http://$HUB_IP:4444/grid/register $CHROME
}

GIT_UPDATE () {
    echo
    echo
    echo "***************************************"
    echo               "Git Update"
    echo "***************************************"
    cd "$SCRIPTPATH"
    git --version
    git fetch origin master
    git reset --hard FETCH_HEAD
    git clean -df
    sleep 2
}

EXIT () {
   exit
}

MENU () {
    while : # Loop forever
    do
    echo
    echo
    echo "***************************************"
    echo              Selenium Grid
    echo "***************************************"
    echo     "1 - Hub"
    echo     "2 - Node (default hub)"
    echo     "3 - Node (specify hub ip address)"
    echo     "4 - Git Update (from stash)"
    echo     "5 - Kill Java"
    echo     "6 - Exit"
    echo
    echo "Type 1, 2, 3 or 4 then press ENTER: "
    read choice
    echo
    case $choice in
        1)
            HUB ;;
        2)
            NODE_DEFAULT ;;
        3)
            NODE_HUB_IP ;;
        4)
            GIT_UPDATE ;;
        5)
            KILL_JAVA ;;
        6)
            EXIT ;;
        *)
            echo "\"$choice\" is not valid "; sleep 2 ;;
    esac
    done
}

echo
echo
echo "***************************************"
echo           "Command Line Switch"
echo "***************************************"
echo command switch = $1
case "$1" in
    1)
        HUB ;;
    2)
        NODE_DEFAULT ;;
    3)
        NODE_HUB_IP ;;
    4)
        GIT_UPDATE ;;
    5)
        KILL_JAVA ;;
    6)
        EXIT ;;
    *)
        MENU ;;
esac
