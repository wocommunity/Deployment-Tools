#! /bin/bash
#  1) Identify (or at least warn) if it will overwrite an existing installation
#  2) Make JavaMonitor optional
#  3) Stop the existing apps if they are running and restart them at the end
#  4) Handle varying file locations and names.  On 10.4 the launchd scripts have different filenames.
#  5) Run without a GUI
#  6) Be usable to update (reinstall) the apps and not just for the initial installation.  This is just a result of the above conditions really.
#  7) EXTRA: be usable on Linux and Windows too

if [ `whoami` != "root" ]; then
echo ""
echo "THIS COMMAND MUST BE RUN WITH SUDO!"	
echo ""
exit 1
fi

echo ""
echo "WARNING: this will replace any installed versions of wotaskd and JavaMonitor and their launch scripts"
echo -n "Are you sure you want to continue? [y/n]: "
read CONTINUE
if [ $CONTINUE != "y" ]; then
exit
fi

echo ""
echo -n "Are you going to run JavaMonitor on this machine [y/n]: "
read USE_MONITOR

cd /Library/LaunchDaemons

if [ ! -f org.projectwonder.wotaskd.plist ]; then
echo "Downloading wotaskd launch"
curl -C - -O https://github.com/wocommunity/Deployment-Tools/LaunchDaemons/org.projectwonder.wotaskd.plist
fi

if [ ! -f org.projectwonder.womonitor.plist ]; then
echo "Downloading womonitor launch"
curl -C - -O https://github.com/wocommunity/Deployment-Tools/LaunchDaemons/org.projectwonder.wotaskd.plist
fi

cd /tmp


if [ $USE_MONITOR == "y" ]; then

	echo "Downloading JavaMonitor"
	curl -O http://webobjects.mdimension.com/hudson/job/Wonder/lastSuccessfulBuild/artifact/dist/JavaMonitor.woa.tar.gz
	
	echo "Unpacking JavaMonitor"
	tar xzf JavaMonitor.woa.tar.gz
	chmod -R 755 JavaMonitor.woa
	chgrp -R wheel JavaMonitor.woa
	
	echo "Installing JavaMonitor"
	if [ -e /Library/WebObjects/JavaApplications/JavaMonitor.woa ]; then
        rm -rf /Library/WebObjects/JavaApplications/JavaMonitor.woa
	fi
	
	if [ !-e /Library/WebObjects/JavaApplications ]; then
        mkdir -p /Library/WebObjects/JavaApplications
	fi

	launchctl unload /Library/LaunchDaemons/org.projectwonder.womonitor.plist
	rm -rf /Library/WebObjects/JavaApplications/JavaMonitor.woa
	mv -f JavaMonitor.woa /Library/WebObjects/JavaApplications/
	
	echo "Starting JavaMonitor"
	launchctl load /Library/LaunchDaemons/org.projectwonder.womonitor.plist
	
	rm JavaMonitor.woa.tar.gz
fi


echo "Downloading wotaskd"
curl -O http://webobjects.mdimension.com/hudson/job/Wonder/lastSuccessfulBuild/artifact/dist/wotaskd.woa.tar.gz

echo "Unpacking wotaskd"
tar xzf wotaskd.woa.tar.gz
chmod -R 755 wotaskd.woa
chgrp -R wheel wotaskd.woa

echo "Installing wotaskd"
launchctl unload /Library/LaunchDaemons/org.projectwonder.wotaskd.plist
if [ -e /Library/WebObjects/JavaApplications/wotaskd.woa ]; then
	rm -rf /Library/WebObjects/JavaApplications/wotaskd.woa
fi

if [ -e /System/Library/WebObjects/JavaApplications ]; then
	mv -f wotaskd.woa /Library/WebObjects/JavaApplications/
fi
launchctl load /Library/LaunchDaemons/org.projectwonder.wotaskd.plist
rm wotaskd.woa.tar.gz

