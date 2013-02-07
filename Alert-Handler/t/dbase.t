#!/usr/bin/perl -w

use Test::More tests => 14;

use Alert::Handler::Dbase;
use Alert::Handler::Xml;
use Alert::Handler::Heartbeat;
use Alert::Handler::Converters;

my $cfg = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');

is($cfg->{'host'}, '192.168.56.101');
is($cfg->{'db'}, 'tk_monitoring');
is($cfg->{'table'}, 'Heartbeats');
is($cfg->{'user'}, 'root');
my $con = getConnection($cfg);
ok($con,'mysql connection');

my $xml_str = '<?xml version="1.0" encoding="UTF-8"?>
<heartbeat version="0.1-dev">
	<authkey category="Monitoring">0123456789a</authkey>
	<date>Thu Oct 11 04:54:34 2012</date>
</heartbeat>';
my $hb_h = parseXmlText($xml_str);
my $heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $hb_h
);

is(HBIsDuplicate($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey(),
	$heartbeat->date()),0,'HB not in DB');
is(insertHB($con,$cfg->{'table'},'test@example.com',$heartbeat->version(),
	$heartbeat->authkey(),$heartbeat->date()),'','inseting HB to DB');
is(getHBDateDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	strToMysqlTime('Thu Oct 11 04:54:34 2012'),'fetching HB Date');
is(HBIsDuplicate($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey(),
	$heartbeat->date()),-1,'HB duplicate with same timestamp');
is(updateHBDate($con,$cfg->{'table'},'Fri Oct 12 04:54:34 2012',
	$heartbeat->version(),$heartbeat->authkey()),'','updating HB date');
is(getHBDateDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	strToMysqlTime('Fri Oct 12 04:54:34 2012'),'fetching modified HB Date');
is(HBIsDuplicate($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey(),
	$heartbeat->date()),1,'HB with timestamp differs');

is(delHBDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),'','deleting HB from DB');


ok(closeConnection($con),'close mysql connection');