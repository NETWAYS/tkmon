package Alert::Handler::Alert;

use warnings;
use strict;
use Carp;
use version;
use Digest::SHA qw(sha512);

our $VERSION = qv('0.0.1');

our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(); # symbols to export
}

sub new{
	my $class = shift;
	my $self = {@_};
	bless ($self,$class);
	$self->_init();
	return $self;
}

sub _init{
	my $self = shift;
	my $xml_h = $self->xmlRoot();
	$self->version($xml_h->{alert}->{version}->{value});
	$self->authkey($xml_h->{alert}->{authkey}->{value});
	$self->date($xml_h->{alert}->{date}->{value});
	$self->hostName($xml_h->{alert}->{host}->{name}->{value});
	$self->hostIP($xml_h->{alert}->{host}->{ip}->{value});
	$self->hostOS($xml_h->{alert}->{host}->{'operating-system'}->{value});
	$self->srvSerial($xml_h->{alert}->{host}->{'server-serial'}->{value});
	$self->compSerial($xml_h->{alert}->{service}->{'component-serial'}->{value});
	$self->compName($xml_h->{alert}->{service}->{'component-name'}->{value});
	$self->srvcName($xml_h->{alert}->{service}->{name}->{value});
	$self->srvcStatus($xml_h->{alert}->{service}->{status}->{value});
	$self->srvcOutput($xml_h->{alert}->{service}->{'plugin-output'}->{value});
	$self->srvcPerfdata($xml_h->{alert}->{service}->{perfdata}->{value});
	$self->srvcDuration($xml_h->{alert}->{service}->{duration}->{value});
	
	#generate the hash and check the xml if it is valid
	$self->check();
	$self->_genHash();
}

sub _genHash{
	my $self = shift;
	my $toHash = $self->srvSerial().$self->srvcName().$self->hostName();
	my $hash = Digest::SHA->new("sha512");
	$hash->add($toHash);
	$self->alertHash($hash->digest());
	if(!defined($self->alertHash())){
		confess("Digest function returned an undefined value.");
	}
}

sub check{
	my $self = shift;
	#skipping component serial/name as they aren't a must have
	if(!defined($self->version()) ||
		!defined($self->authkey()) ||
		!defined($self->date()) ||
		!defined($self->hostName()) ||
		!defined($self->hostIP()) ||
		!defined($self->hostOS()) ||
		!defined($self->srvSerial()) ||
		!defined($self->srvcName()) ||
		!defined($self->srvcStatus()) ||
		!defined($self->srvcOutput()) ||
		!defined($self->srvcPerfdata()) ||
		!defined($self->srvcDuration())){
			confess("Non valid alert XML detected.");
		}
	return;
}

sub xmlRoot { $_[0]->{xmlRoot} = $_[1] if defined $_[1]; $_[0]->{xmlRoot} }
sub alertHash { $_[0]->{alertHash} = $_[1] if defined $_[1]; $_[0]->{alertHash} }
sub version { $_[0]->{version} = $_[1] if defined $_[1]; $_[0]->{version} }
sub authkey { $_[0]->{authkey} = $_[1] if defined $_[1]; $_[0]->{authkey} }
sub date { $_[0]->{date} = $_[1] if defined $_[1]; $_[0]->{date} }
sub hostName { $_[0]->{hostName} = $_[1] if defined $_[1]; $_[0]->{hostName} }
sub hostIP { $_[0]->{hostIP} = $_[1] if defined $_[1]; $_[0]->{hostIP} }
sub hostOS { $_[0]->{hostOS} = $_[1] if defined $_[1]; $_[0]->{hostOS} }
sub srvSerial { $_[0]->{srvSerial} = $_[1] if defined $_[1]; $_[0]->{srvSerial} }
sub compSerial { $_[0]->{compSerial} = $_[1] if defined $_[1]; $_[0]->{compSerial} }
sub compName { $_[0]->{compName} = $_[1] if defined $_[1]; $_[0]->{compName} }
sub srvcName { $_[0]->{srvcName} = $_[1] if defined $_[1]; $_[0]->{srvcName} }
sub srvcStatus { $_[0]->{srvcStatus} = $_[1] if defined $_[1]; $_[0]->{srvcStatus} }
sub srvcOutput { $_[0]->{srvcOutput} = $_[1] if defined $_[1]; $_[0]->{srvcOutput} }
sub srvcPerfdata { $_[0]->{srvcPerfdata} = $_[1] if defined $_[1]; $_[0]->{srvcPerfdata} }
sub srvcDuration { $_[0]->{srvcDuration} = $_[1] if defined $_[1]; $_[0]->{srvcDuration} }


1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Alert - A class to represent a valid notification alert

=head1 VERSION

This document describes Alert::Handler::Alert version 0.0.1

=head1 SYNOPSIS

Example:

	$hb_h = parseXmlFile('../examples/FilterAL.xml');
	my $alert = Alert::Handler::Alert->new(
		xmlRoot => $hb_h
	);
	$tkLogger->info("Xml type: ".getXmlType($hb_h));
	$tkLogger->info("Version: ".$alert->version());
	
=head1 DESCRIPTION

Alert:.Handler::Alert represents an alert object. The object
has as main attributes the corresponding information from the alert
xml. 

=head1 METHODS 

=head2 new

Example:

	my $alert = Alert::Handler::Alert->new(
		xmlRoot => $hb_h
	);
	
The constructor - creates an alert object. $xmlRoot is a parsed xml
reference from XML::Bare and it can be obtained via parseXmlText or
parseXmlFile from the Alert::Handler::Xml module.

=head2 _init

Inits the object attributes with the values from the xml root.
As the xml root has hash references all the values from it must
be assigned seperately to the alert attributes. Moreover _init
checks if all values are defined and throws an exception if any
value is undefined (except component serial or name, as they can
be NULL).
Finally _init generates a unique hash value (currently
SHA512) out of "srvSerial + srvcName + hostName" to detect duplicates
in the database.


=head2 _genHash

Example:
	
	my $alert = Alert::Handler::Alert->new(
		xmlRoot => $hb_h
	);
	unpack("H*",$alert->alertHash());
	
Generates a unique hash for the alert object. Currently SHA512 is
used as hash function. _genHash is automatically called by _init on
alert object documentation.

=head2 check

Example:

	$alert->check();
	
Checks if all values in the xml root are defined and can therfore be
assigned to the alert object.

=head2 xmlRoot

Get the xml root respectively the xml hash.

=head2 alertHash

Example:

	print unpack("H*",$alert->alertHash();
	
Get the calculated unique alert hash value (srvSerial + srvcName + hostName).

=head2 version

Example:

	print $alert->version();
	
Get the alert version.

=head2 authkey

Get the alert auth key.

=head2 date

Get the alert date.

=head2 hostName

Get the hostname the alert comes from.

=head2 hostIP

Get the IP adress the alert was sent from.

=head2 hostOS

Get the operating system the alert was sent from.

=head2 srvSerial

Get the serial number of the server the alert comes from.

=head2 compSerial

Get the serial number of the affected component, if available.

=head2 compName

Get the name of the affected component, if available.

=head2 srvcName

Get the name of the notification service.

=head2 srvcStatus

Get the alert status of the notification service.

=head2 srvcOutput

Get the alert output of the notification service.

=head2 srvcPerfdata

Get the performance data of the notification service.

=head2 srvcDuration

Get the duration the service check took to complete.

=head1 DIAGNOSTICS

=over

=item C<< Non valid alert XML detected. >>

The check function has found some undefined alert values.

=item C<< Digest function returned an undefined value. >>

The unique hash value for the alert could not be calculated.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Alert requires no configuration files.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use Digest::SHA qw(sha512);

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