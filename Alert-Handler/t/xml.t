#!/usr/bin/perl -w

use Test::More tests => 4;

use Alert::Handler::Xml;

my $hb_h = parseXmlHash('../examples/HeartbeatTest.xml');
is(getHBVersion($hb_h), '0.1-dev','heartbeat version');
is(getHBDate($hb_h), 'Thu Oct 11 04:54:34 2012','heartbeat date');
my $authKey = getHBAuthKey($hb_h);
is($authKey->{value},'0123456789a','heartbeat auth key value');
is($authKey->{category}->{value},'Monitoring','heartbeat auth key category');
