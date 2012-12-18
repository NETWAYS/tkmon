package Alert::Handler::Xml;

use warnings;
use strict;
use Carp;
use version;
use XML::Bare;

our $VERSION = qv('0.0.1');

our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(parseXmlFile parseXmlText getXmlType); # symbols to export
}

our $HBROOTTAG = "heartbeat";
our $ALERTROOTTAG = "alert";

sub parseXmlFile{
	my $filename = shift;
	my $xml = new XML::Bare( file => $filename );
	my $root = eval {$xml->parse()};
	if($@){
		confess "Could not parse XML file."
	}
	return $root;
}

sub parseXmlText{
	my $xml_str = shift;
	if(!defined($xml_str)){
		confess "Cannot parse empty xml string.";
	}
	my $xml = new XML::Bare( text => $xml_str );
	my $root = eval {$xml->parse()};
	if($@){
		confess "Could not parse XML string."
	}
	return $root;
}

sub getXmlType{
	my $root = shift;
	if(exists $root->{$HBROOTTAG}){
		return $HBROOTTAG;
	}
	if(exists $root->{$ALERTROOTTAG}){
		return $ALERTROOTTAG;
	}
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Xml - Parse TK monitoring xml files.

=head1 VERSION

This document describes Alert::Handler::Xml version 0.0.1

=head1 SYNOPSIS

Example:

	my $hb_h = parseXmlFile('HeartbeatTest.xml');
	print getHBVersion($hb_h)."\n";
	print getHBDate($hb_h)."\n";
	my $authKey = getHBAuthKey($hb_h);

=head1 DESCRIPTION

Alert::Handler::Xml parses the defined xml structures. The module is able
to handle valid heartbeat and alert xmls.

=head1 METHODS

=head2 parseXmlFile

Example:

	my $hb_h = parseXmlFile('HeartbeatTest.xml');

Parses the xml file, only one parameter is needed - the file path. Returns
a multi-level hash containing the xml structure.

=head2 parseXmlText

Example:

	my $hb_h = parseXmlText($xml_str);

Parses the given xml string. Returns a multi-level hash containing the xml structure.

= getXmlType

Example:

	print getXmlType($hb_h);
	
Returns the type for the given, parsed xml root $hb_h. The type can be
'heartbeat' or 'alert'.

=head2 getHBVersion

Example:

	print getHBVersion($hb_h);

Returns the version tag of the heartbeat xml.

=head2 getHBAuthKey

Example:

	print getHBAuthKey($hb_h);

Returns the authkey tag of the heartbeat xml.

=head2 getHBDate

Example:

	print getHBAuthKey($hb_h);

Returns the date tag (timestamp) of the heartbeat xml.

=head1 DIAGNOSTICS

=over

=item C<< Could not parse XML file. >>

The given xml file could not be parsed by parseXmlFile.

=item C<< Could not parse XML string. >>

The given xml string could not be parsed by parseXmlText.

=item C<< Cannot parse empty xml string. >>

The given xml string to the parsing function is undefined.

=back

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use XML::Bare;

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
