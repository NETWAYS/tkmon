package Alert::Handler::Xml;


use warnings;
use strict;
use Carp;
use version;
use XML::LibXML;
use XML::Bare;

our $VERSION = qv('0.0.1');

our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(parseHBXml parseHBHash); # symbols to export
}

our $HBROOTTAG = "heartbeat";
our $AUTHKEYTAG = "authkey";

sub getAtts{
	my $node = shift;
	my @atts = $node->attributes();
	return \@atts;
}

sub parseNode{
	my $node = shift;
	my %node_h;
	if($node->hasAttributes()){
		$node_h{'attributes'} = getAtts($node);
	}
	$node_h{'name'} = $node->getLocalName();
	$node_h{'text'} = $node->textContent();
	
	return \%node_h;
}

sub parseHBHash{
	my $filename = shift;
	my $xml = new XML::Bare( file => $filename );
	my $root = $xml->parse();
	
}

sub parseHBXml{
	my $filename = shift;
	
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_file($filename);
	my %hb_h;
	
	#grap a node list of heartbeats
	my @hb_nlist = $doc->findnodes($HBROOTTAG);
	if(scalar(@hb_nlist) != 1){
		confess "Found more than one heartbeat root tag in xml!"
	}
	#get the content/childs of the node list
	#we only have one hb tag
	my @xml_l;
	my @nodes = $hb_nlist[0]->nonBlankChildNodes();
	foreach my $tag (@nodes){
		push(@xml_l,parseNode($tag));
	}
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Crypto - Encrypt and decrypt strings with a gpg key.

=head1 VERSION

This document describes Alert::Handler::Crypto version 0.0.1

=head1 SYNOPSIS

Example:


  
=head1 DESCRIPTION



=head1 METHODS 


=head2 readGpgCfg

Example:

	
=head1 DIAGNOSTICS

=over

=item C<< Could not read gpg config. >>

The given config file could not be read by readGpgCfg.

=item C<< Gpg config does not contain the right parameters.. >>

The given config did not contain the right parameter.
 
=back

=head1 CONFIGURATION AND ENVIRONMENT



=head1 DEPENDENCIES
use XML::LibXML;


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
