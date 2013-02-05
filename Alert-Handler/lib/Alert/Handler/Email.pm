package Alert::Handler::Email;

use warnings;
use strict;
use Carp;
use version;
use Email::Simple;
use Mail::Sendmail;

our $VERSION = qv('0.0.1');
our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(parseEmailStr getSubject getBody duplicateEmail replaceSubject 
		replaceBody toString sendEmail); # symbols to export
}

sub parseEmailStr{
	my $msg_str = shift;
	
	#check if msg string is empty
	if(!defined($msg_str)){
		confess "Cannot parse an empty email message string.";
	}
	my $msg = Email::Simple->new($msg_str);
	return $msg;
}

sub getSubject{
	my $msg = shift;
	if(!defined($msg)){confess "Cannot parse an undefined msg.";}
	return $msg->header("Subject");
}

sub getBody{
	my $msg = shift;
	if(!defined($msg)){confess "Cannot parse an undefined msg.";}
	return $msg->body;
}

sub duplicateEmail{
	my $msg = shift;
	my $dupMsg = Email::Simple->new($msg->as_string());
	return $dupMsg;
}

sub replaceSubject{
	my $msg = shift;
	my $newSubj = shift;
	$msg->header_set("Subject", $newSubj);
	return;
}

sub replaceBody{
	my $msg = shift;
	my $newBody = shift;
	$msg->body_set($newBody);
	return;
}

sub toString{
	my $msg = shift;
	if(!defined($msg)){confess "Cannot parse an undefined msg.";}
	return $msg->as_string();
}

sub sendEmail{
	my %params = %{(shift)};
	my %mail = (
		To => $params{to},
		From => $params{from},
		Message => $params{msg}
	);
	$mail{smtp} = $params{smtp};
	sendmail(%mail)
	or confess $Mail::Sendmail::error;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Email - Parse and modify email messages.

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

=head2 duplicateEmail

Example:

	my $dupEmail = duplicateEmail($email);
	
Duplicates/Copies an email (Email::Simple) into a new Email::Simple object.

=head2 replaceSubject

Example:

	replaceSubject($email,'TK-Monitoring modified Subject');

Replaces the subject of the given msg object $email with the second parameter.
$email is an object returned by parseEmailStr.

=head2 replaceBody

Example:

	replaceBody($email,'TK-Monitoring modified Body');

Replaces the body of the given msg object $email with the second parameter.
$email is an object returned by parseEmailStr.

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
	use Email::Simple;

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