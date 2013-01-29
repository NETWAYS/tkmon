#!/usr/bin/perl -w
use strict;
use warnings;
use Try::Tiny;
use IO::File;
use Carp;

use Alert::Handler;
use Alert::Handler::TKLogger;

our $FILTER_DIR = "/etc/postfix/filter";
our $SENDMAIL = "/usr/sbin/sendmail";
our $MAILDIR = "/var/spool/tkmon";#temp dir to store mails

#Exit codes of commands invoked by postfix
our $TEMPFAIL = 75;
our $UNAVAILABLE = 69;

my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => './Logger.cfg'
	);

#Start processing the email
#TODO Temporarily copy email to spool directory for later investigatement
my $msg_str;
while(<STDIN>){
	$msg_str .= $_;
}

#backup mail
saveMail($msg_str,$ARGV[0]);

#Setup up the Handler and decrypt the email
my $tkHandler = Alert::Handler->new(
	sender => $ARGV[0],
	gpgCfg =>'../gnupg/GpgConfig.cfg',
	mysqlCfg => '../mysql/MysqlConfig.cfg',
	logCfg => '../filter/Logger.cfg'
);
try{
	$tkHandler->msg_str($msg_str);
	$tkHandler->parseMsgStr();
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
	} catch{
		$tkLogger->emergency("Failed to handle HB with: ".$_);
		$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded.");
		exit(1);
	};
}
if($tkHandler->xmlType() eq 'alert'){
	try{
		$tkLogger->info("Xml type: ".$tkHandler->xmlType());
		my $ret = $tkHandler->handleAL();
	} catch{
		$tkLogger->emergency("Failed to handle AL with: ".$_);
		$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded.");
		exit(1);
	};
}


sub saveMail{
	my $mail_str = shift;
	my $sender = shift;
	my $time_str = scalar(localtime);
	$time_str =~ s/\s/\_/g;
	my $fname = $MAILDIR.'/'.$sender.'-'.$time_str;
	my $fh = new IO::File "> $fname";
	if(defined $fh){
		print $fh $mail_str;
		$fh->close;
	}
	else{
		confess "Could not save mail from ".$sender." to /var/spool/tkmon/".$fname;
	}
	exit(0);
	return $time_str;
}




__END__

=head1 NAME

TKMonitor - A postfix after-queue filter to process incoming email.