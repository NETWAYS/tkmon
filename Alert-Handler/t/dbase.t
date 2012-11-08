#!/usr/bin/perl -w

use Test::More tests => 3;

use Alert::Handler::Dbase;

my $config = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');

is($config->{'host'}, 'localhost');
is($config->{'db'}, 'Heartbeats');
is($config->{'user'}, 'root');