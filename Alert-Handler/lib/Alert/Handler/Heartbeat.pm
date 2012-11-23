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
	bless ($self,$class	);
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

sub xmlRoot { $_[0]->{xmlRoot} = $_[1] if defined $_[1]; $_[0]->{xmlRoot} }
sub version { $_[0]->{sender} = $_[1] if defined $_[1]; $_[0]->{sender} }
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

=head1 METHODS 

=head2 new

Example:

	my $tkHandler = Alert::Handler->new(
		sender => 'tktest@example.com'
	);
	
The constructor - creates a Handler object.