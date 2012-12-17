package Alert::Handler::Heartbeat;

use warnings;
use strict;
use Carp;
use version;

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
	$self->version($xml_h->{heartbeat}->{version}->{value});
	$self->authkey($xml_h->{heartbeat}->{authkey}->{value});
	$self->date($xml_h->{heartbeat}->{date}->{value});
}

sub check{
	my $self = shift;
	if(!defined($self->version()) ||
		!defined($self->authkey()) ||
		!defined($self->date())){
			confess("Non valid heartbeat XML detected.");
		}
	return;
}

sub xmlRoot { $_[0]->{xmlRoot} = $_[1] if defined $_[1]; $_[0]->{xmlRoot} }
sub version { $_[0]->{version} = $_[1] if defined $_[1]; $_[0]->{version} }
sub authkey { $_[0]->{authkey} = $_[1] if defined $_[1]; $_[0]->{authkey} }
sub date { $_[0]->{date} = $_[1] if defined $_[1]; $_[0]->{date} }


1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Heartbeat - A class to represent a valid heartbeat

=head1 VERSION

This document describes Alert::Handler::Heartbeat version 0.0.1

=head1 SYNOPSIS

Example:

	my $heartbeat = Alert::Handler::Heartbeat->new(
		xmlRoot => $xmlRoot
	);
	$tkLogger->info("Xml type: ".$tkHandler->xmlType());
	$tkLogger->info("Mail sender: ".$tkHandler->sender());
	
=head1 DESCRIPTION

Alert:.Handler::Heartbeat represents a heartbeat object. The object
has as main attributes the corresponding information from the heartbeat
xml. 

=head1 METHODS 

=head2 new

Example:

	my $heartbeat = Alert::Handler::Heartbeat->new(
		xmlRoot => $xmlRoot
	);
	
The constructor - creates a Heartbeat object. $xmlRoot is a parsed xml
reference from XML::Bare and it can be obtained via parseXmlText or
parseXmlFile from the Alert::Handler::Xml module.

=head2 _init

Inits the object attributes with the values from the xml root.
As the xml root is has reference all the values from it must
be assigned seperately to the heartbeat attributes.

=head2 xmlRoot

Get the xml root respectively the xml hash

=head2 version

Example:

	print heartbeat()->version();
	
Get the heartbeat version.

=head2 authkey

Get the heartbeat auth key.

=head2 date

Get the heartbeat date.

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Heartbeat requires no configuration files.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
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
