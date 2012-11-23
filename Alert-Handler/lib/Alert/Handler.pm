package Alert::Handler;

use warnings;
use strict;
use Carp;
use version;

use Alert::Handler::Crypto;
use Alert::Handler::Email;
use Alert::Handler::Xml;
use Alert::Handler::Heartbeat;

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
	bless ($self,$class	);
	return $self;
}

sub sender { $_[0]->{sender} = $_[1] if defined $_[1]; $_[0]->{sender} }
sub receiver { $_[0]->{receiver} = $_[1] if defined $_[1]; $_[0]->{receiver} }
sub gpgCfg { $_[0]->{gpgCfg} = $_[1] if defined $_[1]; $_[0]->{gpgCfg} }
sub msg_str { $_[0]->{msg_str} = $_[1] if defined $_[1]; $_[0]->{msg_str} }
sub msg { $_[0]->{msg} = $_[1] if defined $_[1]; $_[0]->{msg} }
sub msgBody { $_[0]->{msgBody} = $_[1] if defined $_[1]; $_[0]->{msgBody} }
sub xml { $_[0]->{xml} = $_[1] if defined $_[1]; $_[0]->{xml} }
sub xml_h { $_[0]->{xml_h} = $_[1] if defined $_[1]; $_[0]->{xml_h} }
sub xmlType { $_[0]->{xmlType} = $_[1] if defined $_[1]; $_[0]->{xmlType} }

sub parseMsgStr{
	my $self = shift;
	$self->msg(parseEmailStr($self->msg_str));
	$self->msgBody(getBody($self->msg));
	return $self;
}

sub decryptXml{
	my $self = shift;
	my $gpgConfig = readGpgCfg($self->gpgCfg,'gpg');
	$self->xml(decrypt($self->msgBody,$gpgConfig));
	return $self;
}

sub parseXml{
	my $self = shift;
	$self->xml_h(parseXmlText($self->xml()));
	$self->xmlType(getXmlType($self->xml_h));
}

sub handleHB{
	my $xmlRoot = shift;
	my $heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $xmlRoot
	);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler - Work with TK-Monitoring emails

=head1 VERSION

This document describes Alert::Handler version 0.0.1

=head1 SYNOPSIS

Example: