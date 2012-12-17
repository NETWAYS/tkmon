#!/usr/bin/perl -w
use strict;
use warnings;
use Try::Tiny;
#Alert Handler modules to process emails
use Alert::Handler;
use Alert::Handler::Crypto;
use Alert::Handler::Email;
use Alert::Handler::Xml;

our $FILTER_DIR = "/etc/postfix/filter";
#FIXME Insert correct logging directory
our $LOG_DIR = "./";
our $SENDMAIL = "/usr/sbin/sendmail";
#Exit codes of commands invoked by postfix
our $TEMPFAIL = 75;
our $UNAVAILABLE = 69;

#Setup the loggers for monitoring filter and debugging
#TODO Check if logging works with multiple simultanious filter processes
#TODO Maybe we should log directly with syslog?
my $LOGADD = sub {
	my %log_h = @_;
	$log_h{message} = scalar(localtime())." - ".$log_h{message};
	return $log_h{message};
};
use Log::Dispatch;
use Log::Dispatch::File;
my $tkLogger = Log::Dispatch->new();
$tkLogger->add(
	Log::Dispatch::File->new(
		name => 'to_file',
		filename => "$LOG_DIR/tkmonitor.log",
		mode => 'append',
		newline => 1,
		min_level => 'debug',
		max_level => 'emergency',
		callbacks => $LOGADD,
	)
);
my $debugLogger = Log::Dispatch->new();
$debugLogger->add(
	Log::Dispatch::File->new(
		name => 'to_file',
		filename => "$LOG_DIR/debug.log",
		mode => 'append',
		newline => 1,
		min_level => 'debug',
		max_level => 'emergency',
		callbacks => $LOGADD,
	)
);

#Start processing the email
my $msg_str;
while(<STDIN>){
	$msg_str .= $_;
}

#Setup up the Handler and decrypt the email
my $tkHandler = Alert::Handler->new(
	sender => $ARGV[0]
);
try{
	$tkHandler->msg_str($msg_str);
	$tkHandler->parseMsgStr();
	$tkHandler->gpgCfg('../gnupg/GpgConfig.cfg');
	$tkHandler->decryptXml();
} catch{
	$tkLogger->emergency("Failed to parse mail and decrypt XML with: ".$_);
	exit(1);
};
#Check if the email body is not empty
if(!defined($tkHandler->xml())){
#Log which mail has been discarded
	$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded,
	no valid body found.");
	exit(0);
}

#We now have the decrypted XML from the body, now parse it
try{
	$tkHandler->parseXml();
} catch{
	$tkLogger->emergency("Failed to parse XML with: ".$_);
	exit(1);
};
#Check of which type the xml/mail is
if(!defined($tkHandler->xmlType()) ||
	( ($tkHandler->xmlType() ne 'heartbeat') &&
		($tkHandler->xmlType() ne 'alert'))){
	$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded.");
	exit(0);	
}
if($tkHandler->xmlType() eq 'heartbeat'){
	try{
		$tkLogger->info("Xml type: ".$tkHandler->xmlType());
		my $ret = $tkHandler->handleHB();
		#handle HB returns a duplicate
		if($ret == 1){
			$tkLogger->info("Found HB duplicate: ".$tkHandler->heartbeat()->authkey());
		}
		if($ret == 0){
			$tkLogger->info("Insertet new HB in DB: ".$tkHandler->heartbeat()->authkey());
		}
		if($ret == -1){
			$tkLogger->info("HB with same timestamp already in DB: ".$tkHandler->heartbeat()->authkey());
		}
	} catch{
		$tkLogger->emergency("Failed to handle HB with: ".$_);
		exit(1);
	};
}

#$tkLogger->info("Xml type: ".$tkHandler->xmlType());
#$tkLogger->info("Mail sender: ".$tkHandler->sender());
#$tkLogger->info("HB version: ".$tkHandler->heartbeat()->version());









__END__

=head1 NAME

TKMonitor - A postfix after-queue filter to process incoming email.