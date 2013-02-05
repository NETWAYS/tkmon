#!/usr/bin/perl -w
use strict;
use warnings;
use Try::Tiny;

use Alert::Handler;
use Alert::Handler::TKLogger;
use Alert::Handler::Dbase;

my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => './Logger.cfg'
	);
my $cfgPath = './MysqlConf.cfg';

#get DB connection for deleting hearbeat duplicates
my ($mysqlCfg,$DBCon) = getDBConn($cfgPath,'heartbeats');
my $interval = '1 Day';
delDupsDB($DBCon,$mysqlCfg->{'table'},$interval);
#read config to delete alert duplicates, we can use the same db connection here
$mysqlCfg = readMysqlCfg($cfgPath,'alerts');
delDupsDB($DBCon,$mysqlCfg->{'table'},$interval);
closeConnection($DBCon);





sub getDBConn{
	my $cfgPath = shift;
	my $cfgSection = shift;
	my $cfg = readMysqlCfg($cfgPath,$cfgSection);
	my $con = getConnection($cfg);
	return ($cfg, $con);
}




__END__

=head1 NAME

TKMonitor-jobs - A cronjob to delete duplicates older than 24 hours and send
emails to customer who have not sent heartbeats for a certain time.