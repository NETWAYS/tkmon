use Test::More tests => 7;

BEGIN {
use_ok( 'Alert::Handler' );
use_ok( 'Alert::Handler::Crypto' );
use_ok( 'Alert::Handler::Xml' );
use_ok( 'Alert::Handler::Validation' );
use_ok( 'Alert::Handler::Email' );
use_ok( 'Alert::Handler::Dbase' );
use_ok( 'Alert::Handler::Converters' );
}

diag( "Testing Alert::Handler $Alert::Handler::VERSION" );
