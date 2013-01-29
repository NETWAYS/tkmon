package Alert::Handler::Converters;

use warnings;
use strict;
use Carp;
use version;
use DateTime::Format::Strptime;
use DateTime::Format::MySQL;

our $VERSION = qv('0.0.1');
our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(strToDateTime DateTimeToMysql strToMysqlTime DateTimeToStr mysqlToDateTime); # symbols to export
}

sub strToDateTime{
	my $dateStr = shift;
	if(!defined($dateStr)){
		confess "Cannot use undefined date string.";
	}
	my $strp = DateTime::Format::Strptime->new(
		pattern   => '%a %b %d %H:%M:%S %Y',
 		on_error  => 'croak',
	);
	
	my $dt = $strp->parse_datetime($dateStr);
	return $dt;
}

sub DateTimeToMysql{
	my $dt = shift;
	if(!defined($dt)){
		confess "Cannot use undefined date time object.";
	}
	return DateTime::Format::MySQL->format_datetime($dt);
}

sub strToMysqlTime{
	my $dateStr = shift;
	if(!defined($dateStr)){
		confess "Cannot use undefined date string.";
	}
	my $dt = strToDateTime($dateStr);
	return DateTimeToMysql($dt);
}

sub DateTimeToStr{
	my $dt = shift;
	if(!defined($dt)){
		confess "Cannot use undefined date time object.";
	}
	return $dt->strftime('%a %b %d %H:%M:%S %Y');
}

sub mysqlToDateTime{
	my $dateStr = shift;
	if(!defined($dateStr)){
		confess "Cannot use undefined date string.";
	}	
	my $strp = DateTime::Format::Strptime->new(
		pattern   => '%F %H:%M:%S',
 		on_error  => 'croak',
	);
	
	return $strp->parse_datetime($dateStr);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Converters - Several converting functions.

=head1 VERSION

This document describes Alert::Handler::Converters version 0.0.1

=head1 SYNOPSIS

Example

	my $dt = strToDateTime('Thu Oct 11 04:54:34 2012');
	print DateTimeToMysql($dt);

=head1 DESCRIPTION

Alert::Handler::Converters provides functions to convert string and date objects
for the usage in the TK Monitoring application. Especially functions to convert
to mysql formats are needed.

=head1 METHODS 

=head2 strToDateTime

Example:

	my $dt = strToDateTime('Thu Oct 11 04:54:34 2012');

Converts a string containing a date to a Date::Time object. Currenty the following
pattern is supported: '%a %b %d %H:%M:%S %Y' - day of week, month, day of month, 
HH:MM:SS, year (cf. Example above).

=head2 DateTimeToMysql

Example:

	my $str = DateTimeToMysql($dt);

Returns a string in mysql DATETIME format from the given Date::Time object.

=head2 strToMysqlTime

Example:

	strToMysqlTime("Thu Oct 11 04:54:34 2012");

Converts the given date string to a string in mysql DATETIME format.

=head2 DateTimeToStr

Example:

	my $str = DateTimeToStr($dt);

Returns a string represantation of the Date::Time object.

=head2 mysqlToDateTime

Example:

	my $dt = mysqlToDateTime($str);
	
Returns a Date::Time object from the given mysql DATETIME string.

=head1 DIAGNOSTICS

=over

=item C<< Cannot use undefined date string. >>

The given string containing a date is undefined.

=item C<< Cannot use undefined date time object. >>

The given Date::Time object is undefined.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Converters requires no configuration files or environment variables.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use DateTime::Format::Strptime;
	use DateTime::Format::MySQL;

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