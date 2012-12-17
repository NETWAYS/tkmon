package Alert::Handler::TKLogger;

use warnings;
use strict;
use Carp;
use version;
use Log::Dispatch;
use Log::Dispatch::File;

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

my $LOGADD = sub {
	my %log_h = @_;
	$log_h{message} = scalar(localtime())." - ".$log_h{message};
	return $log_h{message};
};

sub _init{
	my $self = shift;
	my $cfgPath = $self->cfgPath();
	my $section = 'log';
	if(!defined($cfgPath) || !defined($section)){
		confess "Cannot use empty config path or empty section."
	}
	my %logCfg;
	eval{
		tie %logCfg, 'Config::IniFiles', (-file => $cfgPath);
	};
	if($@){
		confess "Could not read logger config";
	}
	my %cfgSection =  %{$logCfg{$section}};
	$self->file($cfgSection{'file'});
	$self->level($cfgSection{'level'});
	my $tkLogger = Log::Dispatch->new();
	$tkLogger->add(
		Log::Dispatch::File->new(
			name => 'to_file',
			filename => $self->file(),
			mode => 'append',
			newline => 1,
			min_level => $self->level(),
			max_level => 'emergency',
			callbacks => $LOGADD,
		)
	);
	$self->logger($tkLogger);
}

sub info(){
	my $self = shift;
	my $msg =shift;
	$self->logger()->info($msg);
}

sub emergency(){
	my $self = shift;
	my $msg =shift;
	$self->logger()->emergency($msg);
}

sub cfgPath { $_[0]->{cfgPath} = $_[1] if defined $_[1]; $_[0]->{cfgPath} }
sub file { $_[0]->{file} = $_[1] if defined $_[1]; $_[0]->{file} }
sub level { $_[0]->{level} = $_[1] if defined $_[1]; $_[0]->{level} }
sub logger { $_[0]->{logger} = $_[1] if defined $_[1]; $_[0]->{logger} }

1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::TKLogger - A logger for TK monitoring.

=head1 VERSION

This document describes Alert::Handler::TKLogger version 0.0.1

=head1 SYNOPSIS

Example:

	my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => './Logger.cfg'
	);
	$tkLogger->emergency("Failed to handle HB with: ".$_);

=head1 DESCRIPTION

Alert::Handler::TKLogger uses Log::Dispatch to log to a specified log file.

=head1 METHODS

=head2 info

Example:

	$tkLogger->info("HB with same timestamp already in DB: ".$heartbeat->authkey());

Calls the info level warning and logs the given message.

=head1 DIAGNOSTICS

=over

=item C<< Could not read logger config >>

The given config file could not be parsed correctly.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Validation requires one configuration file to specify 
the log file and the desired log level.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use Log::Dispatch;
	use Log::Dispatch::File;

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
