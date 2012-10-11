package Alert::Handler::Crypto;


use warnings;
use strict;
use Carp;
use Crypt::GPG;
use Safe;
use version;
our $VERSION = qv('0.0.1');

our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(readGpgCfg encrypt decrypt); # symbols to export
}

sub readGpgCfg{
	my $cfgPath = shift;
	my $gpgCfg = Safe->new->rdo($cfgPath);
	if(ref($gpgCfg) ne "HASH"){
		confess "Could not read gpg config.";
	}
	if(not exists $gpgCfg->{'gpgbin'} ||
	not exists $gpgCfg->{'secretkey'} ||
	not exists $gpgCfg->{'passphrase'}){
		confess "Gpg config does not contain the right parameters.";
	}
	return $gpgCfg;
}

sub encrypt{
	my $plaintext = shift;
	my $recipient = shift;
	
	my $gpg = new Crypt::GPG;
	my $encrypted = $gpg->encrypt($plaintext,$recipient);
	return $encrypted;
}

sub decrypt{
	my $encrypted = shift;
	my $config_h = shift;
	
	my $gpg = new Crypt::GPG;
	$gpg->gpgbin($config_h->{'gpgbin'});      # The GnuPG executable.
	$gpg->secretkey($config_h->{'secretkey'});     # Set ID of default secret key.
	$gpg->passphrase($config_h->{'passphrase'});  # Set passphrase.

	my $decrypted = $gpg->verify($encrypted);
	return $decrypted;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Crypto - Encrypt and decrypt strings with a gpg key.

=head1 VERSION

This document describes Alert::Handler::Crypto version 0.0.1

=head1 SYNOPSIS

Example:

	use Alert::Handler::Crypto;
	my $config = readGpgCfg('../gnupg/GpgConfig.cfg');
	my $encrypted = encrypt($plaintext,'tktest@example.com');
	my $decrypted = decrypt($encrypted,$config);
  
=head1 DESCRIPTION

Alert::Handler::Crypto interacts with an imported gpg key and provides
methosd to en- and decrypt message strings with the configured key. The
key that is used for en-/decryption is specified in a config file. Before
any cipher method can be called this config file must be read out with
readGpgCfg in order to parse key ID and passphrase.

=head1 METHODS 

=head2 readGpgCfg

Example:

	my $config = readGpgCfg('../gnupg/GpgConfig.cfg');

Reads a config file with the gpg config parameters in it. Returns a hash
of the read parameters.

Example config file:

	{
	gpgbin => '/usr/bin/gpg',
	secretkey => '0x9B6B1E58',
	passphrase => 'tktest',
	}

=head2 encrypt

Example:

	my $encrypted = encrypt($plaintext,'tktest@example.com');

Encrpyts the string in $plaintext for the given email as a second argument.
The public key of the given email must be present as imported gpg key.

=head2 decrypt

Example:

	my $decrypted = decrypt($encrypted,$config);

Decrypts the ciphertext given by $encrypted. The $config is a valid config hash
returned by readGpgCfg.
	
=head1 DIAGNOSTICS

=over

=item C<< Could not read gpg config. >>

The given config file could not be read by readGpgCfg.

=item C<< Gpg config does not contain the right parameters.. >>

The given config did not contain the right parameter.
 
=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Alert::Handler::Crypto requires one configuration file to
specify which gpg key to use. A call to readGpgCfg needs the
path to this file in order to parse the file and init the 
config hash.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use Crypt::GPG;
	use Safe;
	use version;

=head1 AUTHOR

Georg Schönberger  C<< <gschoenberger@thomas-krenn.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Georg Schönberger C<< <gschoenberger@thomas-krenn.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
