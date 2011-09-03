#! /bin/bash

################################################
## chmod -R 755 deploy.sh
## sudo ./deploy.sh
################################################

echo "*********************************************************";
echo "WebObject Deployment for OSX Lion Server";
echo "2011 by WOdka Team";
echo "v. 1.2";
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
    echo "Creating FolderStructure"
    mkdir /Library/WebObjects
	mkdir /Library/WebObjects/Configuration
	mkdir /Library/WebObjects/Logs
	mkdir /Library/WebObjects/Adaptors
	mkdir /Library/WebObjects/Deployment
	mkdir /Library/WebObjects/Application
	mkdir /Library/WebObjects/WebServerResource
    chown -R _appserver:_appserveradm /Library/WebObjects
    chmod -R 755 /Library/WebObjects
fi

################################################
## Download plist for LaunchD
################################################
cd /Library/LaunchDaemons

if [ ! -f org.projectwonder.wotaskd.plist ]; then
	echo "Downloading wotaskd launch"
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/org.projectwonder.wotaskd.plist
fi

if [ ! -f corg.projectwonder.womonitor.plist ]; then
	echo "Downloading womonitor launch"
	curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/org.projectwonder.womonitor.plist
fi

################################################
## UNLOAD
################################################
launchctl unload -w org.projectwonder.womonitor.plist
launchctl unload -w org.projectwonder.wotaskd.plist

################################################
## INSTALLING wotaskd
## http://webobjects.mdimension.com/hudson/job/Wonder/lastSuccessfulBuild/artifact/dist/wotaskd.woa.tar.gz
## or
## http://dl.dropbox.com/u/1548210/Downloads/WODeployment/wotaskd.woa.tar.gz
################################################
cd /tmp

echo "Downloading wotaskd"
curl -O http://webobjects.mdimension.com/hudson/job/Wonder/lastSuccessfulBuild/artifact/dist/wotaskd.woa.tar.gz

echo "Unpacking wotaskd"
tar xzf wotaskd.woa.tar.gz
chmod -R 755 wotaskd.woa
chown -R _appserver:wheel wotaskd.woa

echo "Installing wotaskd"
rm -rf /Library/WebObjects/Deployment/wotaskd.woa
mv -f wotaskd.woa /Library/WebObjects/Deployment/
rm wotaskd.woa.tar.gz

chmod 750 /Library/WebObjects/Deployment/wotaskd.woa/Contents/Resources/SpawnOfWotaskd.sh
chmod 750 /Library/WebObjects/Deployment/wotaskd.woa/wotaskd

################################################
## wotask コマンドライン起動
## sudo -u _appserver /Library/WebObjects/Deployment/wotaskd.woa/wotaskd &
################################################

################################################
## INSTALLING JavaMonitor
## http://webobjects.mdimension.com/hudson/job/Wonder/lastSuccessfulBuild/artifact/dist/JavaMonitor.woa.tar.gz
## or
## http://dl.dropbox.com/u/1548210/Downloads/WODeployment/JavaMonitor.woa.tar.gz
################################################
cd /tmp

echo "Downloading JavaMonitor"
curl -O http://webobjects.mdimension.com/hudson/job/Wonder/lastSuccessfulBuild/artifact/dist/JavaMonitor.woa.tar.gz

echo "Unpacking JavaMonitor"
tar xzf JavaMonitor.woa.tar.gz
chmod -R 755 JavaMonitor.woa
chown -R _appserver:wheel JavaMonitor.woa

echo "Installing JavaMonitor"
rm -rf /Library/WebObjects/Deployment/JavaMonitor.woa
mv -f JavaMonitor.woa /Library/WebObjects/Deployment/
rm JavaMonitor.woa.tar.gz

################################################
## JavaMonitor コマンドライン起動
## sudo -u _appserver /Library/WebObjects/Deployment/JavaMonitor.woa/JavaMonitor -WOPort 56789 &
################################################

################################################
## LOAD
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
## Sample Database
################################################
echo ""
echo -n "Are you going to Install the Sample App [y/n]: "
read USE_DEMO

if [ $USE_MONITOR == "y" ]; then
	if [ -f /Library/FrontBase/Databases/Movies.fb ]; then 
		cd /tmp
		
		echo "Downloading Sample Application"
		curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/SampleDeployTest-0iw-Application.tar.gz
		curl -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/SampleDeployTest-0iw-WebServerResources.tar.gz
	
		echo "Unpacking Sample Application"
		tar xfz SampleDeployTest-0iw-Application.tar.gz  -C /Library/WebObjects/Application
		tar xfz SampleDeployTest-0iw-WebServerResources.tar.gz -C /Library/WebObjects/WebServerResource
	
		echo "Installing JavaMonitor"
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
## Monitor : Test Property
## -Xmx256M
## -Duser.name=production
################################################

################################################
## APACHE
################################################

cd /Library/WebObjects/Adaptors

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

################################################
## Create SymbolicLink for WebServerResource
## Depends on the Site
################################################

clear
echo "*********************************************************";
echo "Go to your SiteFolder and create a SymbolicLink to the WebServerResource";
echo "cd /Library/Server/Web/Data/Sites/<Your SiteFolder>";
echo "sudo ln -s /Library/WebObjects/WebServerResource WebObjects";
echo "*********************************************************";
