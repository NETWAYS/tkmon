use Test::More tests => 6;

BEGIN {
use_ok( 'Alert::Handler::Crypto' );
use_ok( 'Alert::Handler::Xml' );
use_ok( 'Alert::Handler::Validation' );
use_ok( 'Alert::Handler::Email' );
use_ok( 'Alert::Handler::Dbase' );
use_ok( 'Alert::Handler::Converters' );
}

diag( "Testing Alert::Handler::Crypto $Alert::Handler::Crypto::VERSION" );
