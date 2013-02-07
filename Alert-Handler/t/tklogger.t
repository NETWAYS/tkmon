#!/usr/bin/perl -w

use Test::More tests => 2;

use Alert::Handler::TKLogger;

my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => './t/test-log.cfg'
	);
	
is($tkLogger->cfgPath(),'./t/test-log.cfg','tklogger config path');
is($tkLogger->level(),'debug','tklogger log level');