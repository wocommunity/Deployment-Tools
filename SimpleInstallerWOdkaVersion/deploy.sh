#! /bin/bash

################################################
## chmod -R 755 deploy.sh
## sudo ./deploy.sh
################################################

echo "*********************************************************";
echo "WebObject Deployment for OSX Lion Server";
echo "2011-12 by WOdka Team (Ken Ishimoto)";
echo "v. 1.3 Last Modify : 2012-03-18";
echo "*********************************************************";
echo ""

if [ `whoami` != "root" ]; then
	echo ""
	echo "THIS COMMAND MUST BE RUN WITH SUDO!"	
	echo ""
	exit 1
fi

echo "WARNING: this will replace any installed versions of wotaskd and JavaMonitor and their launch scripts"
echo -n "Are you sure you want to continue? [y/n]: "
read CONTINUE
if [ $CONTINUE != "y" ]; then
	exit
fi

################################################
## 保存されるファイル：SiteConfig.xml (wotask使用)
## 保存パス必要 /Library/WebObjects/Configuration 
################################################

if [ ! -d /Library/WebObjects ]; then 
    echo "Creating Project Wonder ultimate FolderStructure"
    mkdir /Library/WebObjects
	mkdir /Library/WebObjects/Configuration
	mkdir /Library/WebObjects/Logs
	mkdir /Library/WebObjects/Adaptors
	mkdir /Library/WebObjects/Deployment
	mkdir /Library/WebObjects/Application
	mkdir /Library/WebObjects/WebServerResource
    chown -R _appserver:_appserveradm /Library/WebObjects
    chmod -R 755 /Library/WebObjects
    chmod -R 775 /Library/WebObjects/Logs/
fi

################################################
## Download plist for LaunchD
################################################

cd /Library/LaunchDaemons

if [ ! -f org.projectwonder.wotaskd.plist ]; then
	echo "Downloading wotaskd launch"
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/org.projectwonder.wotaskd.plist
fi

if [ ! -f org.projectwonder.womonitor.plist ]; then
	echo "Downloading womonitor launch"
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/org.projectwonder.womonitor.plist
fi

if [ ! -f org.projectwonder.woreboot_temp.plist ]; then
	echo "Downloading woreboot launch"
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/org.projectwonder.woreboot_temp.plist
fi

################################################
## UNLOAD
################################################
echo "Stop JavaMonitor, 'Error unloading' can happens it's OK"
launchctl unload -w org.projectwonder.womonitor.plist

echo "Stop wotask, 'Error unloading' can happens it's OK"
launchctl unload -w org.projectwonder.wotaskd.plist

if [ -f org.projectwonder.woreboot.plist ]; then
	echo "Stop WOReboot, 'Error unloading' can happens it's OK"
	launchctl unload -w org.projectwonder.woreboot.plist
fi

################################################
## INSTALLING wotaskd 2012/03/16
## http://jenkins.wocommunity.org/job/Wonder/lastSuccessfulBuild/artifact/Root/Roots/wotaskd.tar.gz
################################################
## wotask Commandline Test Command
## sudo -u _appserver /Library/WebObjects/Deployment/wotaskd.woa/wotaskd &
################################################

if [ ! -d /Library/WebObjects/Deployment/wotaskd.woa ]; then
	cd /tmp

	echo "Downloading wotaskd"
	curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/wotaskd.tar.gz

	echo "Unpacking wotaskd"
	tar xzf wotaskd.tar.gz
	chmod -R 755 wotaskd.woa
	chown -R _appserver:wheel wotaskd.woa

	echo "Installing wotaskd"
	rm -rf /Library/WebObjects/Deployment/wotaskd.woa
	mv -f wotaskd.woa /Library/WebObjects/Deployment/
	rm wotaskd.tar.gz

	chmod 750 /Library/WebObjects/Deployment/wotaskd.woa/Contents/Resources/SpawnOfWotaskd.sh
	chmod 750 /Library/WebObjects/Deployment/wotaskd.woa/wotaskd
fi

################################################
## INSTALLING JavaMonitor 2012/03/16
## http://jenkins.wocommunity.org/job/Wonder/lastSuccessfulBuild/artifact/Root/Roots/JavaMonitor.tar.gz
################################################
## JavaMonitor Commandline Test Command
## sudo -u _appserver /Library/WebObjects/Deployment/JavaMonitor.woa/JavaMonitor -WOPort 56789 &
################################################

if [ ! -d /Library/WebObjects/Deployment/JavaMonitor.woa ]; then
	cd /tmp

	echo "Downloading JavaMonitor"
	curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/JavaMonitor.tar.gz

	echo "Unpacking JavaMonitor"
	tar xzf JavaMonitor.tar.gz
	chmod -R 755 JavaMonitor.woa
	chown -R _appserver:wheel JavaMonitor.woa

	echo "Installing JavaMonitor"
	rm -rf /Library/WebObjects/Deployment/JavaMonitor.woa
	mv -f JavaMonitor.woa /Library/WebObjects/Deployment/
	rm JavaMonitor.tar.gz
fi

################################################
## Sample Database
## There are 2 Sample Apps
## 1. if FrontBase was installed with the fbdeploy script
##    and has running the Movie DB it will use the Sample-with-FB
## 2. otherwise it will use the Sample without Database Connection
## The Sample App has only a Text, Image (to see WOResource is correct)
## and in the case of FrontBase one Line of a Movie to show that the Database
## connection is OK.
################################################

echo ""
echo -n "Are you going to Install the Sample App [y/n]: "
read USE_DEMO

if [ $USE_DEMO == "y" ]; then
	if [ -f /Library/FrontBase/Databases/Movies.fb ]; then 
		cd /tmp
		
		echo "Downloading Sample Application"
		curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/SampleDeployTest-0iw-Application.tar.gz
		curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/SampleDeployTest-0iw-WebServerResources.tar.gz
	
		echo "Unpacking Sample Application"
		tar xfz SampleDeployTest-0iw-Application.tar.gz  -C /Library/WebObjects/Application
		tar xfz SampleDeployTest-0iw-WebServerResources.tar.gz -C /Library/WebObjects/WebServerResource
	
		echo "Installing Sample Application"
		chmod -R 755 /Library/WebObjects/Application/SampleDeployTest-0iw.woa
		chown -R _appserver:wheel /Library/WebObjects/Application/SampleDeployTest-0iw.woa
		chmod -R 755 /Library/WebObjects/WebServerResource/SampleDeployTest-0iw.woa
		chown -R _appserver:wheel /Library/WebObjects/WebServerResource/SampleDeployTest-0iw.woa
		chmod a+rx /Library/WebObjects/Application/SampleDeployTest-0iw.woa/SampleDeployTest-0iw
	
		rm SampleDeployTest-0iw-Application.tar.gz
		rm SampleDeployTest-0iw-WebServerResources.tar.gz
	else
		cd /tmp
		
		echo "Downloading Sample Application"
		curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/SampleDeployNoDB-0iw-Application.tar.gz
		curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/SampleDeployNoDB-0iw-WebServerResources.tar.gz
	
		echo "Unpacking Sample Application"
		tar xfz SampleDeployNoDB-0iw-Application.tar.gz  -C /opt/Application
		tar xfz SampleDeployNoDB-0iw-WebServerResources.tar.gz -C /opt/WebServerResource
		
		echo "Installing Sample Application"
		chmod -R 755 /Library/WebObjects/Application/SampleDeployNoDB-0iw.woa
		chown -R _appserver:wheel /Library/WebObjects/Application/SampleDeployNoDB-0iw.woa
		chmod -R 755 /Library/WebObjects/WebServerResource/SampleDeployNoDB-0iw.woa
		chown -R _appserver:wheel /Library/WebObjects/WebServerResource/SampleDeployNoDB-0iw.woa    
		chmod a+rx /Library/WebObjects/Application/SampleDeployNoDB-0iw.woa/SampleDeployNoDB-0iw
		
		rm SampleDeployNoDB-0iw-Application.tar.gz
		rm SampleDeployNoDB-0iw-WebServerResources.tar.gz
	fi
fi

################################################
## APACHE
################################################

cd /Library/WebObjects/Adaptors

if [ ! -f mod_WebObjects.so ]; then
	echo "Installing Apache configuration"

	##http://webobjects.mdimension.com/wonder/mod_WebObjects/Apache2.2/macosx/10.6/mod_WebObjects.so
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/mod_WebObjects.so

	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/wo_apache.conf
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/wo_expires.conf
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/wo_rewrite.conf
	chown -R _appserver:_appserveradm /Library/WebObjects/Adaptors

	cd /etc/apache2
	cp httpd.conf httpd.conf.backup

	echo "Include /Library/WebObjects/Adaptors/wo_rewrite.conf" >> httpd.conf
	echo "Include /Library/WebObjects/Adaptors/wo_expires.conf" >> httpd.conf
	echo "Include /Library/WebObjects/Adaptors/wo_apache.conf" >> httpd.conf

	apachectl restart
fi

################################################
## Console : to make it easier to view the Log
################################################

cd /Library/Logs
if [ ! -d WebObjects ]; then
	echo "Create Symboliklink for Console.App to find WebObjects Log";
	ln -s /Library/WebObjects/Logs/ WebObjects
fi

################################################
## LOAD JavaMonitor
################################################
cd /Library/LaunchDaemons

echo "Starting wotask"
launchctl load -w org.projectwonder.wotaskd.plist

echo ""
echo -n "Are you going to run JavaMonitor on this machine [y/n]: "
read USE_MONITOR

if [ $USE_MONITOR == "y" ]; then
	echo "Starting JavaMonitor"
	launchctl load -w org.projectwonder.womonitor.plist
fi

################################################
## Install the WOReboot to reboot after the Launch
## Thanks to the WOdka Member : ASTONISH-CREATE
################################################

echo ""
echo -n "Are you going to run WO Automatic Reboot on this machine [y/n]: "
read USE_REBOOT

if [ $USE_REBOOT == "y" ]; then
	cd /Library/LaunchDaemons

	echo ""
	echo -n "What's your Mail Address? "
	read MAIL_ADD

	if [ $MAIL_ADD != "" ]; then
		sed -e 's/mailaddress/'$MAIL_ADD'/' org.projectwonder.woreboot_temp.plist > org.projectwonder.woreboot.plist
		rm org.projectwonder.woreboot_temp.plist
	fi

	echo "Starting woreboot"
	launchctl load -w org.projectwonder.woreboot.plist
fi

################################################
## Create SymbolicLink for WebServerResource
## Depends on the Site
################################################

clear
echo "*********************************************************";
echo "Set your JavaMonitor settings like";
echo "";
echo "-Xmx256M";
echo "-Duser.name=production";
echo "*********************************************************";
echo "Go to your SiteFolder and create a SymbolicLink to the WebServerResource";
echo "";
echo "cd /Library/Server/Web/Data/Sites/<Your SiteFolder>";
echo "sudo ln -s /Library/WebObjects/WebServerResource WebObjects";
echo "*********************************************************";

exit 0
