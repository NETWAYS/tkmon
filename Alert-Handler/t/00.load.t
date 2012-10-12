use Test::More tests => 3;

BEGIN {
use_ok( 'Alert::Handler::Crypto' );
use_ok( 'Alert::Handler::Email' );
use_ok( 'Alert::Handler::Validation' );
}

diag( "Testing Alert::Handler::Crypto $Alert::Handler::Crypto::VERSION" );
