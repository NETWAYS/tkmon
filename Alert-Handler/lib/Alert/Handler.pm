package Alert::Handler;

use warnings;
use strict;
use Carp;
use version;

use Alert::Handler::Crypto;
use Alert::Handler::Email;
use Alert::Handler::Xml;
use Alert::Handler::Dbase;
use Alert::Handler::Converters;
use Alert::Handler::Validation;
use Alert::Handler::TKLogger;
use Alert::Handler::Heartbeat;

our $VERSION = qv('0.0.1');
my $MYSQL_CFG = '../mysql/MysqlConfig.cfg';
my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => '../filter/Logger.cfg'
	);

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
sub heartbeat { $_[0]->{heartbeat} = $_[1] if defined $_[1]; $_[0]->{heartbeat} }

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

sub initMysql{
	my $cfgSection = shift;
	my $cfg = readMysqlCfg($MYSQL_CFG,$cfgSection);
	my $con = getConnection($cfg);
	return ($cfg, $con);
}

sub handleHB{
	my $self = shift;
	my $heartbeat = Alert::Handler::Heartbeat->new(
		xmlRoot => $self->xml_h()
	);
	
	#check heartbeat xml tags
	$heartbeat->check();
	
	$self->heartbeat($heartbeat);
	if(valAuthKey($heartbeat->authkey()) ne '200'){
		$tkLogger->info("Auth key not valid: ".$self->sender().', '.$heartbeat->authkey());
		return;
	}
	my ($mysqlCfg,$DBCon) = initMysql('heartbeats');
	my $ret;
	$ret = HBIsDuplicate($DBCon,$mysqlCfg->{'table'},
		$heartbeat->version(),$heartbeat->authkey(),strToMysqlTime($heartbeat->date()));
	#found a duplicate
	if($ret == 1){
		updateHBDate($DBCon,$mysqlCfg->{'table'},
			strToMysqlTime($heartbeat->date()),
			$heartbeat->version(),$heartbeat->authkey());
		$tkLogger->info("Found HB duplicate: ".$heartbeat->authkey());
	}
	#HB not in DB
	if($ret == 0){
		insertHB($DBCon,$mysqlCfg->{'table'},$self->sender(),
			$heartbeat->version(),$heartbeat->authkey(),strToMysqlTime($heartbeat->date()));
		$tkLogger->info("Inserted new HB in DB: ".$heartbeat->authkey());
	}
	if($ret == -1){
		$tkLogger->info("HB with same timestamp already in DB: ".$heartbeat->authkey());
	}
	closeConnection($DBCon);
	return;
}
1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler - The main module to handle emails, xml, heartbeats, alerts
and mysql connections.

=head1 VERSION

This document describes Alert::Handler version 0.0.1

=head1 SYNOPSIS

Example:

	my $tkHandler = Alert::Handler->new(
		sender => $ARGV[0]
	);
	$tkHandler->msg_str($msg_str);
	$tkHandler->parseMsgStr();
	$tkHandler->gpgCfg('../gnupg/GpgConfig.cfg');
	$tkHandler->decryptXml();
	
=head1 DESCRIPTION

Alert::Handler parses an email, exctracts the xml, parses the xml and
creates the corresponding objects (heartbeats, alerts). It is also responsible
for checking if these objects must be inserted/updated to the mysql database.

=head1 METHODS

=head2 new

Example:

	my $tkHandler = Alert::Handler->new(
		sender => $ARGV[0]
	);
	
Constructor - creates a new Handler object.

=head2 sender

Get/set the sender of the email.

=head2 receiver

Get/set the receiver of the email.

=head2 gpgCfg

Get/set the gpg configuration file path.

=head2 msg_str

Get/set the email as string.

=head2 msg

Example:

	$self->msg(parseEmailStr($self->msg_str));

The email as Email::Simple object, can be obtained via parseEmailStr.

=head2 msgBody

Get/set the body of the Email::Simple object.

=head2 xml

Get/set the xml from the email as string. This string can be parsed with
parseXmlText.

=head2 xml_h

Example:

	$self->xml_h(parseXmlText($self->xml()));

The xml string is parsed into an XML::Bare object.

=head2 xmlType

Get/set the type of the xml - heartbeat or alert.

=head2 heartbeat

Get/set the heartbeat attribute.

=head2 parseMsgStr

Example:

	$tkHandler->msg_str($msg_str);
	$tkHandler->parseMsgStr();
	
Parses the email as string into an Email::Simple object. Then
extracts and sets the parts of the email (body, subject).

=head2 decryptXml

Example:

	$tkHandler->gpgCfg('../gnupg/GpgConfig.cfg');
	$tkHandler->decryptXml();
	
Decrypts the XML from the email message.

=head2 parseXml

Parse the xml from the email message. The email must be decrypted an parsed
into body etc. before the xml can be parsed.

=head2 initMysql

Example:

	my ($mysqlCfg,$DBCon) = initMysql('heartbeats');
	
Establish a mysql connection and read out the given section of the
configuration file. The config file path is a static class variable.

=head2 handleHB

Handles a heartbeat object - checks if the auth key is valid, if the timestamp
must be updated in the database or if the heartbeat has to inserted into the
database.

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Heartbeat requires a configuration file to establish
the database connection.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use version;
	use Alert::Handler::Crypto;
	use Alert::Handler::Email;
	use Alert::Handler::Xml;
	use Alert::Handler::Dbase;
	use Alert::Handler::Converters;
	use Alert::Handler::Validation;
	use Alert::Handler::TKLogger;
	use Alert::Handler::Heartbeat;

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