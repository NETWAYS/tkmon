#!/usr/bin/perl -w

use Test::More tests => 3;

use Alert::Handler::Dbase;

my $config = readMysqlCfg("../mysql/MysqlConfig.cfg");

is($config->{'heartbeats'}{'host'}, 'localhost');
is($config->{'heartbeats'}{'db'}, 'Heartbeats');
is($config->{'heartbeats'}{'user'}, 'root');