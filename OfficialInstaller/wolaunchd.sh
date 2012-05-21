#! /bin/bash
#  1) Identify (or at least warn) if it will overwrite an existing installation
#  2) Make JavaMonitor optional
#  3) Stop the existing apps if they are running and restart them at the end
#  4) Run without a GUI
#  5) Be usable to update (reinstall) the apps and not just for the initial installation.  This is just a result of the above conditions really.

# TODO: Deal with changes to Apache configuration file also.

echo ""
echo "Welcome to the WebObjects Deployment Installation Script, courtesy of developers at wocommunity.org."
echo ""
echo "If you have questions about this script or about WebObjects installation in general, go to http://www.community.org"
echo "or to http://wiki.objectstyle.org/confluence/display/WO/Deployment."
echo ""
echo "Thank you for your support."
echo ""

if [ `whoami` != "root" ]; then
    echo ""
    echo "THIS COMMAND MUST BE RUN WITH SUDO!"	
    echo ""
    exit 1
fi

echo "WARNING: this will replace any installed versions of wotaskd and JavaMonitor and their launch scripts."
echo -n "Are you sure you want to continue? [y/n]: "
read CONTINUE
if [ "$CONTINUE" != "y" ]; then
    exit
fi

echo ""
echo -n "Are you going to run JavaMonitor on this machine [y/n]: "
read USE_MONITOR

cd /Library/LaunchDaemons

if [ ! -f org.projectwonder.wotaskd.plist ]; then
echo "Downloading wotaskd launch"
curl --insecure -C - -O https://raw.github.com/wocommunity/Deployment-Tools/master/OfficialInstaller/LaunchDaemons/org.projectwonder.wotaskd.plist
fi

if [ ! -f org.projectwonder.womonitor.plist ]; then
echo "Downloading womonitor launch"
curl --insecure -C - -O https://raw.github.com/wocommunity/Deployment-Tools/master/OfficialInstaller/LaunchDaemons/org.projectwonder.womonitor.plist
fi

cd /tmp

# Download everything first so that we minimize downtime (in case we're updating a production server)
if [ $USE_MONITOR == "y" ]; then
	echo "Downloading JavaMonitor"
	curl -O http://jenkins.wocommunity.org/job/WonderIntegration/lastSuccessfulBuild/artifact/Root/Roots/JavaMonitor.tar.gz
	
	echo "Unpacking JavaMonitor"
	tar xzf JavaMonitor.tar.gz
	chmod -R 755 JavaMonitor.woa
	chown -R appserver wotaskd.woa
	chgrp -R wheel JavaMonitor.woa
fi

echo "Downloading wotaskd"
curl -O http://jenkins.wocommunity.org/job/WonderIntegration/lastSuccessfulBuild/artifact/Root/Roots/wotaskd.tar.gz

echo "Unpacking wotaskd"
tar xzf wotaskd.tar.gz
chmod -R 755 wotaskd.woa
chown -R appserver wotaskd.woa
chgrp -R wheel wotaskd.woa

# Remove OLD applications and launchd scripts
if [ -f /System/Library/LaunchDaemons/com.apple.webobjects.wotaskd.plist ]; then
    launchctl unload /System/Library/LaunchDaemons/com.apple.webobjects.wotaskd.plist
    launchctl unload /System/Library/LaunchDaemons/com.apple.webobjects.womonitor.plist

    rm -f /System/Library/LaunchDaemons/com.apple.webobjects.wotaskd.plist
    rm -f /System/Library/LaunchDaemons/com.apple.webobjects.womonitor.plist
fi

if [ -f /Library/LaunchDaemons/com.apple.webobjects.wotaskd.plist ]; then
    launchctl unload /Library/LaunchDaemons/com.apple.webobjects.wotaskd.plist
    launchctl unload /Library/LaunchDaemons/com.apple.webobjects.womonitor.plist

    rm -f /Library/LaunchDaemons/com.apple.webobjects.wotaskd.plist
    rm -f /Library/LaunchDaemons/com.apple.webobjects.womonitor.plist
fi

rm -rf /System/Library/WebObjects/JavaApplications/JavaMonitor.woa
rm -rf /System/Library/WebObjects/JavaApplications/wotaskd.woa/Contents/
rm -rf /System/Library/WebObjects/JavaApplications/wotaskd.woa/wotaskd
rm -rf /System/Library/WebObjects/JavaApplications/wotaskd.woa/wotaskd.cmd
# leave WOBootstrap.jar in case this is a development machine and this is needed for woproject

mkdir -p /Library/WebObjects/Configuration/
mkdir -p /Library/WebObjects/Applications/
mkdir -p /Library/WebObjects/Logs
mkdir -p /Library/WebObjects/JavaApplications
mkdir -p /System/Library/WebObjects/Adaptors/Apache2.2
mkdir -p /etc/WebObjects

chown appserver /Library/WebObjects/Configuration
chown appserver /Library/WebObjects/Applications
chown appserver /Library/WebObjects/Logs
chown appserver /Library/WebObjects/JavaApplications

if [ $USE_MONITOR == "y" ]; then
	echo "Installing JavaMonitor"
	if [ -e /Library/WebObjects/JavaApplications/JavaMonitor.woa ]; then
        rm -rf /Library/WebObjects/JavaApplications/JavaMonitor.woa
	fi
	
	launchctl unload /Library/LaunchDaemons/org.projectwonder.womonitor.plist
	rm -rf /Library/WebObjects/JavaApplications/JavaMonitor.woa
	mv -f JavaMonitor.woa /Library/WebObjects/JavaApplications/
	
	mkdir -p /Library/WebServer/Documents/WebObjects/JavaMonitor.woa/Contents/
	ln -s /Library/WebObjects/JavaApplications/JavaMonitor.woa/Contents/WebServerResources /Library/WebServer/Documents/WebObjects/JavaMonitor.woa/Contents/

	echo "Starting JavaMonitor"
	launchctl load /Library/LaunchDaemons/org.projectwonder.womonitor.plist
	
	rm JavaMonitor.tar.gz
fi


echo "Installing wotaskd"
launchctl unload /Library/LaunchDaemons/org.projectwonder.wotaskd.plist
if [ -e /Library/WebObjects/JavaApplications/wotaskd.woa ]; then
	rm -rf /Library/WebObjects/JavaApplications/wotaskd.woa
fi

if [ -e /Library/WebObjects/JavaApplications ]; then
	mv -f wotaskd.woa /Library/WebObjects/JavaApplications/
fi
launchctl load /Library/LaunchDaemons/org.projectwonder.wotaskd.plist
rm wotaskd.tar.gz


function configureApache2dot2() {
  if [ -d /etc/apache2 ]; then
	if [ ! -f /System/Library/WebObjects/Adaptors/Apache2.2/mod_WebObjects.so ]; then
		echo "Downloading mod_WebObjects"
		curl -O http://wocommunity.org/documents/tools/mod_WebObjects/Apache2.2/macosx/10.6/mod_WebObjects.so
		chmod a+x mod_WebObjects.so
		mv mod_WebObjects.so /System/Library/WebObjects/Adaptors/Apache2.2/
	fi

	if [ ! -f /System/Library/WebObjects/Adaptors/Apache2.2/apache.conf ]; then
		echo "Downloading apache.conf for WebObjects"
		curl -O https://raw.github.com/wocommunity/Deployment-Tools/master/OfficialInstaller/apache.conf
		mv apache.conf /System/Library/WebObjects/Adaptors/Apache2.2/
	fi

	IS_APACHE_CONFIGURED=`grep "Include /System/Library/WebObjects/Adaptors/Apache2.2/apache.conf" /etc/apache2/httpd.conf`
	if [ "$IS_APACHE_CONFIGURED" == "" ]; then
		echo "Configuring and restarting apache. You may need to change or comment out the ScriptAlias directive in http.conf"
		echo "Include /System/Library/WebObjects/Adaptors/Apache2.2/apache.conf" >> /etc/apache2/httpd.conf
		apachectl restart
	fi
  fi
}

#configureApache2dot2

echo ""
ps auxww | grep "\-WOPort 1085" | grep -v "grep"
echo ""
ps auxww | grep "\-WOPort 56789" | grep -v "grep"
echo ""
