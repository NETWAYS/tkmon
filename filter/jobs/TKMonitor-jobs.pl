#!/usr/bin/perl -w
use strict;
use warnings;
use Try::Tiny;

use Alert::Handler;
use Alert::Handler::TKLogger;
use Alert::Handler::Dbase;
use Alert::Handler::Email;

my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => './Logger.cfg'
	);
	
my $cfgPath = '../../mysql/MysqlConfig.cfg';
my ($HBCfg,$DBCon) = getDBConn($cfgPath,'heartbeats');

#delete entries from duplicate DB
my $interval = '1 Day';
#delDupsDB($DBCon,$HBCfg->{'table'},$interval);
my $ALCfg = readMysqlCfg($cfgPath,'alerts');
#delDupsDB($DBCon,$ALCfg->{'table'},$interval);

my $mails;#which customers to send mail to
my $mailsSupport;#list of emails to send to support
try{
	#get email adresses for reminders from heartbeats
	$interval = '50 Hour';
	$mails = getEmailAdrDB($DBCon,$HBCfg->{'table'},$interval);
	$interval = '75 Hour';
	$mailsSupport = getEmailAdrDB($DBCon,$HBCfg->{'table'},$interval);
	closeConnection($DBCon);
}
catch{
	$tkLogger->emergency("Failed to get email addresses from DB with: ".$_);
};
#send emails to each mail address
my $msg = "Attention: TKmonitor did not receive any heartbeat for more than 
50 hours. Pleas check your TKmonitor setup or contact support.";

foreach my $email (@$mails){
	try{
		sendHBReminders($msg,$email);
	}
	catch{
		$tkLogger->emergency("Failed to send HB reminder email to $email with: ".$_);
	};
}
$msg = "The following TKmonitoring system have not sent any heartbeats for more than 
75 hours:\n";
#FIXME Insert email address from TK support
my $suppEmail = 'gschoenberger@thomas-krenn.com';

foreach my $email (@$mailsSupport){
	$msg .= "- ".$email ."\n";
}
try{
	sendHBReminders($msg,$suppEmail);
}
catch{
	$tkLogger->emergency("Failed to send HB reminder email to support with: ".$_);
};

sub getDBConn{
	my $cfgPath = shift;
	my $cfgSection = shift;
	my $cfg = readMysqlCfg($cfgPath,$cfgSection);
	my $con = getConnection($cfg);
	return ($cfg, $con);
}

sub sendHBReminders{
	my $msg = shift;
	my $recv = shift;
	my $mailToSend = {
		from => 'monitor@thomas-krenn.com',
		to => $recv,
		msg => $msg,
		subject => 'TKMonitor Reminder',
		smtp => 'zimbra.thomas-krenn.com'
	};
	sendEmail($mailToSend);
}


__END__

=head1 NAME

TKMonitor-jobs - A cronjob to delete duplicates older than 24 hours and send
emails to customer who have not sent heartbeats for a certain time.