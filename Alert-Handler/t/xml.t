#!/usr/bin/perl -w

use Test::More tests => 10;

use Alert::Handler::Xml;

my $xml_str = '<?xml version="1.0" encoding="UTF-8"?>
<heartbeat version="0.1-dev">
	<authkey category="Monitoring">0123456789a</authkey>
	<date>Thu Oct 11 04:54:34 2012</date>
</heartbeat>';

my $hb_h = parseXmlFile('../examples/HeartbeatTest.xml');
is(getXmlType($hb_h), 'heartbeat','xml type heartbeat');
is(getHBVersion($hb_h), '0.1-dev','heartbeat version');
is(getHBDate($hb_h), 'Thu Oct 11 04:54:34 2012','heartbeat date');
my $authKey = getHBAuthKey($hb_h);
is($authKey->{value},'0123456789a','heartbeat auth key value');
is($authKey->{category}->{value},'Monitoring','heartbeat auth key category');

undef $hb_h;
undef $authKey;
$hb_h = parseXmlText($xml_str);
is(getXmlType($hb_h), 'heartbeat','xml type heartbeat');
is(getHBVersion($hb_h), '0.1-dev','heartbeat version');
is(getHBDate($hb_h), 'Thu Oct 11 04:54:34 2012','heartbeat date');
$authKey = getHBAuthKey($hb_h);
is($authKey->{value},'0123456789a','heartbeat auth key value');
is($authKey->{category}->{value},'Monitoring','heartbeat auth key category');