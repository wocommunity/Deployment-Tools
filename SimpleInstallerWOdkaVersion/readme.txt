How to Install

cd /tmp
curl -C - -O http://dl.dropbox.com/u/1548210/Downloads/WODeployment/deploy.sh
chmod -R 755 deploy.sh
sudo ./deploy.sh

--

After finish the Installation, create an SymbolicLink to your WebSitefolder.

################################################
## Create SymbolicLink for WebServerResource
## Depends on the Site
################################################
cd /Library/Server/Web/Data/Sites/YOURSITEFOLDER
sudo ln -s /Library/WebObjects/WebServerResource WebObjects



--

Parameter for SampleApp in JavaMonitor like

-Xmx256M
-Duser.name=production


See : http://www.ksroom.com/cgi-bin/WebObjects/Kisa.woa/wa/woDeploy