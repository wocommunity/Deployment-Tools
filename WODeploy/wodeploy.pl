#!/usr/bin/perl

#use strict;
use REST::Client;
use JSON;
use File::Rsync;
use Net::SSH::Perl;
use POSIX;
use Getopt::Long;
use vars qw($opt_U $opt_n $opt_p $opt_P);

$PATH_TO_WOROOT = "/opt/Local/Library/WebObjects";
$PATH_TO_WSR = "/opt/Local/Library/WebServer/Documents/WebObjects/";
$PATH_TO_APP = $PATH_TO_WOROOT . "/Applications/";
$PATH_TO_LOGS = $PATH_TO_WOROOT . "/Logs/";
$MONITOR_HOST = "your.server.com";
$APP_USERNAME = "appserver";
$PATH_TO_SSHKEY = "/var/lib/jenkins/.ssh/id_rsa";
$PATH_TO_SSH = "/usr/bin/ssh";
$PATH_TO_RSYNC = "/usr/bin/rsync";
$OS_TYPE = "unix"; # change it to "mac" if you deploy on OS X

Getopt::Long::Configure('bundling');
GetOptions
	("U=s" => \$opt_U, "url=s" 		=> \$opt_U,
	 "n=s" => \$opt_n, "name=s"    => \$opt_n,
	 "p=s" => \$opt_p, "password=s"    => \$opt_p,
	 "P=s" => \$opt_P, "path=s"    => \$opt_P,
	 "W=s" => \$opt_W, "wsr=s"    => \$opt_W);

($opt_U) || ($opt_U = shift) || print_usage("URL to JavaMonitor not specified\n");
($opt_n) || ($opt_n = shift) || print_usage("Application not specified\n");
($opt_P) || ($opt_P = shift) || print_usage("Path to application not specified\n");
($opt_p) || ($opt_p = shift);
($opt_W) || ($opt_W = shift);

my $json = JSON->new->allow_nonref;
my $client = REST::Client->new();

my $is_archive = 0;
my $wsr_present = 0;
my $wsr_path;
my $archive_name;
my $wsr_archive_name;
my $is_wsr_archive = 0;
my $script_name;
my $app_new_name;
($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $current_time = ($year + 1900) . ($mon + 1) . $mday . $hour . $min;

my $url_to_Monitor = $opt_U . "/ra/mApplications/";
my $url_end = ".json";
my $app_path = $opt_P;
my $app_name = $opt_n;

if ($opt_U =~ m/http\:\/\/(.*)\:.*\/.*/gi) {
	$MONITOR_HOST = $1;
}

if (defined($opt_p)) {
	$url_end = $url_end . "&pw=" . $opt_p;
}
if (defined($opt_w)) {
	$wsr_present = 1;
	$wsr_path = $opt_W;
}

print "Checking if the archive is valid...\n";

my @splitResults = split(/\//,$app_path);
my $app_bin_name = $splitResults[$#splitResults];
if (($app_bin_name  =~ m/(.*)\.woa.*\.tgz/gi) or ($app_bin_name =~ m/(.*)\.woa.*\.tar.gz/gi) or ($app_bin_name =~ m/(.*)\-Application\.tar\.gz/gi) or ($app_bin_name =~ m/(.*)\-Application\.tgz/gi)) { 
	$is_archive = 1;
	$archive_name = $app_bin_name;
	$app_bin_name = $1 . ".woa";
} elsif ($app_bin_name =~ m/(.*)\.woa/gi) {
	$script_name = $1;
} else {
	print_usage("App binary not ending with .woa\n");
}

@splitResults = split(/\//,$wsr_path);
my $wsr_archive_name = $splitResults[$#splitResults];
if (($wsr_archive_name  =~ m/(.*)\.woa.*\.tgz/gi) or ($wsr_archive_name =~ m/(.*)\.woa.*\.tar.gz/gi) or ($wsr_archive_name =~ m/(.*)\-WebServerResources\.tar\.gz/gi) or ($wsr_archive_name =~ m/(.*)\-WebServerResources\.tgz/gi)) { 
	$is_wsr_archive = 1;
	$wsr_archive_name = $wsr_archive_name;
	$wsr_archive_name = $1 . ".woa";
}

my %appArgs = ();
$appArgs{"id"} = $app_name;
$appArgs{"type"} = "MApplication";
$appArgs{"name"} = $app_name;
if ($OS_TYPE eq "mac") {
	$appArgs{"macOutputPath"} = $PATH_TO_LOGS;
	$appArgs{"macPath"} = $PATH_TO_APP . $app_bin_name . "/" . $script_name;
} else {
	$appArgs{"unixOutputPath"} = $PATH_TO_LOGS;
	$appArgs{"unixPath"} = $PATH_TO_APP . $app_bin_name . "/" . $script_name;
}

print "Checking if the app already exist in configuration...\n";

my $appExists = 0;
$client->GET($url_to_Monitor . $app_name . $url_end);
if ($client->responseCode() >= 200 and $client->responseCode() < 400) {
	$appExists = 1;
	# App exists, so let's refuse new sessions
	my $refuseNewSessionsUrl = $opt_U . "/admin/turnRefuseNewSessionsOn?type=app&name=" . $app_name;
	if (defined($opt_p)) {
		$refuseNewSessionsUrl = $refuseNewSessionsUrl . "&pw=" . $opt_p;
	}
	$client->GET($refuseNewSessionsUrl);
} 

print "Sending the build to the server...\n";

my $rsync = File::Rsync->new( { archive => 1, compress => 1, rsh => $PATH_TO_SSH, 'rsync-path' => $PATH_TO_RSYNC, verbose => 0 } );
$rsync->exec( {src => $app_path, dest => $APP_USERNAME . "\@" . $MONITOR_HOST . ":/tmp/" }) or die $rsync->err;
if ($wsr_present == 1) {
	$rsync->exec( {src => $wsr_path, dest => $APP_USERNAME . "\@" . $MONITOR_HOST . ":/tmp/" }) or die $rsync->err;
}

print "Moving the build and redoing the symlink...\n";

my $ssh = Net::SSH::Perl->new($MONITOR_HOST, "identity_files" => [ $PATH_TO_SSHKEY ], "debug" => 0);
$ssh->login($APP_USERNAME);
if ($is_archive == 1) {
	my($stdout, $stderr, $exit) = $ssh->cmd("cd /tmp; tar zxf /tmp/" . $archive_name);
}
$app_new_name = $app_bin_name . "-" . $current_time;
my($stdout, $stderr, $exit) = $ssh->cmd("mv /tmp/" . $app_bin_name . " " . $PATH_TO_APP . $app_new_name);
my($stdout, $stderr, $exit) = $ssh->cmd("rm -rf " . $PATH_TO_APP . $app_bin_name);
my($stdout, $stderr, $exit) = $ssh->cmd("ln -s " . $PATH_TO_APP . $app_new_name . " " . $PATH_TO_APP . $app_bin_name);

if ($wsr_present == 1) {
	if ($is_wsr_archive == 1) {
		my($stdout, $stderr, $exit) = $ssh->cmd("cd /tmp; tar zxf /tmp/" . $wsr_path);	
	}
	my($stdout, $stderr, $exit) = $ssh->cmd("mv /tmp/" . $app_bin_name . " " . $PATH_TO_APP . $app_new_name);
	my($stdout, $stderr, $exit) = $ssh->cmd("ln -s " . $PATH_TO_WSR . $app_bin_name . " " . $PATH_TO_WSR . $app_bin_name);
    my($stdout, $stderr, $exit) = $ssh->cmd("chmod -R o+r,o+x " + $PATH_TO_WSR);
} else {
	my($stdout, $stderr, $exit) = $ssh->cmd("cp -rp " . $PATH_TO_APP . $app_new_name . " " . $PATH_TO_WSR . $app_new_name);
	my($stdout, $stderr, $exit) = $ssh->cmd("rm " . $PATH_TO_WSR . $app_bin_name);
	my($stdout, $stderr, $exit) = $ssh->cmd("ln -s " .  $PATH_TO_WSR . $app_new_name . " " . $PATH_TO_WSR . $app_bin_name);
	my($stdout, $stderr, $exit) = $ssh->cmd("rm -r " . $PATH_TO_WSR . $app_new_name . "/Contents/MacOS");
	my($stdout, $stderr, $exit) = $ssh->cmd("rm -r " . $PATH_TO_WSR . $app_new_name . "/Contents/UNIX");
	my($stdout, $stderr, $exit) = $ssh->cmd("rm -r " . $PATH_TO_WSR . $app_new_name . "/Contents/Windows");
	my($stdout, $stderr, $exit) = $ssh->cmd("rm -r " . $PATH_TO_WSR . $app_new_name . "/Contents/Resources");
	my($stdout, $stderr, $exit) = $ssh->cmd("rm -r " . $PATH_TO_WSR . $app_new_name . "/Contents/Info.plist");
}


if ($appExists == 0) {
	print "Adding the app to JavaMonitor and starting it...\n";
	$client->POST($url_to_Monitor . ".json?pw=" . $opt_p, $json->encode( \%appArgs ));
	if ($client->responseCode() >= 200 and $client->responseCode() < 400) {
		$client->GET($url_to_Monitor . $app_name . "/addInstance" . $url_end);
	}
} else {
	print "Restarting the app...\n";
	my $stopUrl = $opt_U . "/admin/stop?type=app&name=" . $app_name;
	my $startUrl = $opt_U . "/admin/start?type=app&name=" . $app_name;
	if (defined($opt_p)) {
		$stopUrl = $stopUrl . "&pw=" . $opt_p;
		$startUrl = $startUrl . "&pw=" . $opt_p;
	}
	$client->GET($stopUrl);
	$client->GET($startUrl);
}

print "All done!\n";

sub print_usage () {
	print "Usage: monitor.pl -U <urlToJavaMonitor> -n <appName> -P <pathToApplicationBundle> [-p <password>]\n";
    exit;
}