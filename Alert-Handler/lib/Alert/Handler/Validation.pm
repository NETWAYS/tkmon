package Alert::Handler::Validation;

use warnings;
use strict;
use Carp;
use version;
use WWW::Curl::Easy;

our $HB_REST_URL = 'https://www.thomas-krenn.com/api/v1/monitoring/heartbeat';
our $SER_REST_URL = 'https://www.thomas-krenn.com/api/v1/monitoring/service/';

our $VERSION = qv('0.0.1');
our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(valAuthKey); # symbols to export
}

sub valAuthKey{
	my $authKey = shift;
	my $serial = shift;
	
	my $curl = WWW::Curl::Easy->new;
	#$curl->setopt(CURLOPT_VERBOSE,1);
	
	#use a different URL for serial combinations
	if($serial){
		$curl->setopt(CURLOPT_URL,$SER_REST_URL.$serial);
	}
	else{
		$curl->setopt(CURLOPT_URL,$HB_REST_URL);
	}
	
	#put in the aut key with an empty password
	$curl->setopt(CURLOPT_USERPWD,"$authKey:''");
	my @headers = ('Content-Length: 0');
	$curl->setopt(CURLOPT_HTTPHEADER, \@headers);
	$curl->setopt(CURLOPT_CUSTOMREQUEST, 'PUT');
	#$curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);
	#$curl->setopt(CURLOPT_SSL_VERIFYHOST, 0);
	
	if((my $ret = $curl->perform) != 0){
		confess "Could not perform REST call";
	}
	return $curl->getinfo(CURLINFO_HTTP_CODE);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Validation - Validate Alerts/Serials via REST API

=head1 VERSION

This document describes Alert::Handler::Validation version 0.0.1

=head1 SYNOPSIS

Example:
	
	my $retCode = valAuthKey('9WNa8V2P86Q');
	my $retCode = valAuthKey('r2XW84Nfi6v','9000091290');

=head1 DESCRIPTION

Alert::Handler::Validation calls two different REST APIs - one for
alert heartbeats and one for serial numbers. Both APIs require a
valid auth key to return 200 on success. Else 403 as an invalidation
notice is returned. In order to check an auth/serial combination a
valid serial number must be provided as a second argument.

=head1 METHODS 

=head2 valAuthKey

Example:

	my $retCode = valAuthKey('9WNa8V2P86Q');
	my $retCode = valAuthKey('r2XW84Nfi6v','9000091290');
	
Calls the REST API with libcurl an returns the status http code. If the second
parameter is defined it must be a valid serial number.

Return Codes for auth keys:

=over

=item 403 - Not a valid auth key.

=item 200 - A valid auth key.

=back

Return Codes for auth/serial combinations:

=over

=item 403 - Not a valid auth/serial key.

=item 402 - Payment required, service not valid for auth/serial.

=back

=head1 DIAGNOSTICS

=over

=item C<< Could not perform REST call. >>

The call to the libcurl library to carry out the request 
returned an error.
 
=back

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Validation requires no configuration files or environment variables.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use WWW::Curl::Easy;

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
