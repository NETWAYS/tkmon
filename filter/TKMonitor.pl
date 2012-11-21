#!/usr/bin/perl -w

use strict;
use warnings;
use Try::Tiny;

#Alert Handler modules to process emails
use Alert::Handler::Crypto;
use Alert::Handler::Email;
use Alert::Handler::Xml;

use feature qw(say);

#Setup the logger
use Log::Dispatch;
use Log::Dispatch::File;
my $tkLogger = Log::Dispatch->new();
$tkLogger->add(
	Log::Dispatch::File->new(
		name => 'to_file',
		filename => 'tkmonitor.log',
		mode => 'append',
		min_level => 'debug',
		max_level => 'emergency',
	)
);

#Start processing the email
my $msg_str;
while(<STDIN>){
	$msg_str .= $_;
}

#parse the email
my $msg = try{
	parseEmailStr($msg_str);
} catch{
	$tkLogger->emergency("Failed with: $_");
}; 

#decrypt the body with a specified key
my $encBody_str;
my $gpgConfig;
my $xml_str;
try{
	$encBody_str = getBody($msg);
	$gpgConfig = readGpgCfg('../gnupg/GpgConfig.cfg');
	$xml_str = decrypt($encBody_str,$gpgConfig);
	#assume for now it is a heartbeat
	my $hb_h = parseXmlText($xml_str);
	#As a first test print the heartbeat version
	$tkLogger->info("HB version: ".getHBVersion($hb_h));	
} catch{
	$tkLogger->emergency("Failed with: $_");
	exit(1);
};

__END__

=head1 NAME

TKMonitor - A postfix after-queue filter to process incoming email.