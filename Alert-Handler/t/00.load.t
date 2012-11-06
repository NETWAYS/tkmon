use Test::More tests => 4;

BEGIN {
use_ok( 'Alert::Handler::Crypto' );
use_ok( 'Alert::Handler::Xml' );
use_ok( 'Alert::Handler::Validation' );
use_ok( 'Alert::Handler::Email' );
}

diag( "Testing Alert::Handler::Crypto $Alert::Handler::Crypto::VERSION" );
