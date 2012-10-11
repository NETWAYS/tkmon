#!/usr/bin/perl -w

use Test::More tests => 4;

use Alert::Handler::Validation;

is(valAuthKey('9WNa8V2P86Q'),'200', 'successful return Code of HB REST');
is(valAuthKey('9ENa8V5P87Z'),'403', 'invalid return Code of HB REST');
is(valAuthKey('r2XW84Nfi6v','9000091290'),'402', 'successful return Code of SER REST');
is(valAuthKey('9ENa8V5P87Z','9000091290'),'403', 'invalid return Code of SER REST');
