#!/usr/bin/perl -w

use Test::More tests => 8;

use Alert::Handler::Xml;
use Alert::Handler::Heartbeat;

my $xml_str = '<?xml version="1.0" encoding="UTF-8"?>
<heartbeat version="0.1-dev">
	<authkey category="Monitoring">0123456789a</authkey>
	<date>Thu Oct 11 04:54:34 2012</date>
</heartbeat>';

my $hb_h = parseXmlFile('../examples/HeartbeatTest.xml');
my $heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $hb_h
);
is(getXmlType($hb_h), 'heartbeat','xml type heartbeat');
is($heartbeat->version(), '0.1-dev','heartbeat version');
is($heartbeat->date(), 'Mon Dec 17 10:19:34 2012','heartbeat date');
is($heartbeat->authkey(),'0123456789a','heartbeat auth key value');

undef $hb_h;
undef $heartbeat;
$hb_h = parseXmlText($xml_str);
$heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $hb_h
);
is(getXmlType($hb_h), 'heartbeat','xml type heartbeat');
is($heartbeat->version(), '0.1-dev','heartbeat version');
is($heartbeat->date(), 'Thu Oct 11 04:54:34 2012','heartbeat date');
is($heartbeat->authkey(),'0123456789a','heartbeat auth key value');