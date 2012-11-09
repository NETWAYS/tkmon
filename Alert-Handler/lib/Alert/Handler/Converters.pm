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
	@EXPORT = qw(strToDateTime DateTimeToMysql strToMysqlTime); # symbols to export
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

1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Converters - Several converting functions.

=head1 VERSION

This document describes Alert::Handler::Email version 0.0.1


=head1 SYNOPSIS

Example

	use Alert::Handler::Email;
	my $email = parseEmailStr($email_str);
	my $subject = getSubject($email);
	my $modifiedEmail = replaceSubject($email,'TK-Monitoring modified Subject');
	my $subject = getSubject($modifiedEmail);
	my $body = getBody($email);

  
=head1 DESCRIPTION

Alert::Handler::Email parses RFC2822 email messages. The parsing methods work with
msg objects, in order to get such an object the parseEmailStr method has to be called.
This method takes an email as string as an argument an returns a msg object.

=head1 METHODS 

=head2 parseEmailStr

Example:

	my $email = parseEmailStr($email_str);

Parses $email_str, a email message as string. Returns an Email::Simple msg object
for further usage.

=head2 getSubject

Example:

	my $subject = getSubject($email);
	
Returns the subject of the given msg object $email - $email is an object
returned by parseEmailStr.

=head2 getBody

Example:

	my $body = getBody($email);
	
Returns the body of the given msg object $email - $email is an object
returned by parseEmailStr.

=head2 replaceSubject

Example:

	my $modifiedEmail = replaceSubject($email,'TK-Monitoring modified Subject');
	
Replaces the subject of the given msg object $email with the second parameter.
$email is an object returned by parseEmailStr, the function returns a new msg object
with the modified subject.

=head2 toString

Example:

	print toString($modifiedEmail);
	
Returns the msg object as string.

=head1 DIAGNOSTICS

=over

=item C<< Cannot parse an empty email message string. >>

The given email string to parseEmailStr is empty.

=item C<< Cannot parse an undefined msg. >>

The email msg object is undefined.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Email requires no configuration files or environment variables.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use DateTime::Format::Strptime;
	
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
