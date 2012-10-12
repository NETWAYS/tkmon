use Test::More tests => 3;

BEGIN {
use_ok( 'Alert::Handler::Crypto' );
use_ok( 'Alert::Handler::Xml' );
use_ok( 'Alert::Handler::Validation' );
}

diag( "Testing Alert::Handler::Crypto $Alert::Handler::Crypto::VERSION" );
