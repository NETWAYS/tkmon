#!/usr/bin/perl -w

use Test::More tests => 4;

use Alert::Handler::Dbase;

my $config = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');

is($config->{'host'}, '192.168.56.101');
is($config->{'db'}, 'tk_monitoring');
is($config->{'table'}, 'Heartbeats');
is($config->{'user'}, 'root');