#!/usr/bin/perl -w

use Test::More tests => 4;

use Alert::Handler::Crypto;

my $plaintext = 'The quick brown fox jumps over the lazy dog';
my $config = readGpgCfg('../gnupg/GpgConfig.cfg');

is($config->{'gpgbin'}, '/usr/bin/gpg','gpg binary');
is($config->{'secretkey'}, '0x9B6B1E58','gpg seckey id');
is($config->{'passphrase'}, 'tktest','gpg passphrase');

my $encrypted = encrypt($plaintext,'tktest@example.com');
my $decrypted = decrypt($encrypted,$config);
is($decrypted,$plaintext,'testing decryption');