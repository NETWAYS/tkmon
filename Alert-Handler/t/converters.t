#!/usr/bin/perl -w

use Test::More tests => 2;

use Alert::Handler::Converters;

my $dt = strToDateTime('Thu Oct 11 04:54:34 2012');
is(DateTimeToMysql($dt), '2012-10-11 04:54:34');
is(strToMysqlTime('Thu Oct 11 04:54:34 2012'), '2012-10-11 04:54:34');