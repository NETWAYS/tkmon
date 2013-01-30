package Alert::Handler;

use warnings;
use strict;
use Carp;
use version;

use Alert::Handler::Crypto;
use Alert::Handler::Email;
use Alert::Handler::Xml;
use Alert::Handler::Dbase;
use Alert::Handler::Validation;
use Alert::Handler::TKLogger;
use Alert::Handler::Heartbeat;
use Alert::Handler::Alert;

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
	if(!defined($self->logCfg())){
		confess "Cannot use empty config path as logCfg."
	}
	my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => $self->logCfg()
	);
	$self->logger($tkLogger);
}

sub sender { $_[0]->{sender} = $_[1] if defined $_[1]; $_[0]->{sender} }
sub receiver { $_[0]->{receiver} = $_[1] if defined $_[1]; $_[0]->{receiver} }
sub gpgCfg { $_[0]->{gpgCfg} = $_[1] if defined $_[1]; $_[0]->{gpgCfg} }
sub mysqlCfg { $_[0]->{mysqlCfg} = $_[1] if defined $_[1]; $_[0]->{mysqlCfg} }
sub logCfg { $_[0]->{logCfg} = $_[1] if defined $_[1]; $_[0]->{logCfg} }
sub logger { $_[0]->{logger} = $_[1] if defined $_[1]; $_[0]->{logger} }
sub msg_str { $_[0]->{msg_str} = $_[1] if defined $_[1]; $_[0]->{msg_str} }
sub msg { $_[0]->{msg} = $_[1] if defined $_[1]; $_[0]->{msg} }
sub msg_plain { $_[0]->{msg_plain} = $_[1] if defined $_[1]; $_[0]->{msg_plain} }
sub msgBody { $_[0]->{msgBody} = $_[1] if defined $_[1]; $_[0]->{msgBody} }
sub xml { $_[0]->{xml} = $_[1] if defined $_[1]; $_[0]->{xml} }
sub xml_h { $_[0]->{xml_h} = $_[1] if defined $_[1]; $_[0]->{xml_h} }
sub xmlType { $_[0]->{xmlType} = $_[1] if defined $_[1]; $_[0]->{xmlType} }
sub heartbeat { $_[0]->{heartbeat} = $_[1] if defined $_[1]; $_[0]->{heartbeat} }
sub alert { $_[0]->{alert} = $_[1] if defined $_[1]; $_[0]->{alert} }


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
	my $self = shift;
	my $cfgSection = shift;
	my $cfg = readMysqlCfg($self->mysqlCfg(),$cfgSection);
	my $con = getConnection($cfg);
	return ($cfg, $con);
}

sub handleHB{
	my $self = shift;
	my $heartbeat = Alert::Handler::Heartbeat->new(
		xmlRoot => $self->xml_h()
	);
	
	$self->heartbeat($heartbeat);
	if(valAuthKey($heartbeat->authkey()) ne '200'){
		$self->logger()->info("Auth key not valid: ".$self->sender().', '.$heartbeat->authkey());
		return;
	}
	my ($mysqlCfg,$DBCon) = $self->initMysql('heartbeats');
	my $ret;
	$ret = HBIsDuplicate($DBCon,$mysqlCfg->{'table'},
		$heartbeat->version(),$heartbeat->authkey(),$heartbeat->date());
	#found a duplicate
	if($ret == 1){
		updateHBDate($DBCon,$mysqlCfg->{'table'},
			$heartbeat->date(),
			$heartbeat->version(),$heartbeat->authkey());
		$self->logger()->info("Found HB duplicate: ".$heartbeat->authkey());
	}
	#HB not in DB
	if($ret == 0){
		insertHB($DBCon,$mysqlCfg->{'table'},$self->sender(),
			$heartbeat->version(),$heartbeat->authkey(),$heartbeat->date());
		$self->logger()->info("Inserted new HB in DB: ".$heartbeat->authkey());
	}
	if($ret == -1){
		$self->logger()->info("HB with same timestamp already in DB: ".$heartbeat->authkey());
	}
	closeConnection($DBCon);
	return;
}

sub handleAL{
	my $self = shift;
	my $alert = Alert::Handler::Alert->new(
		xmlRoot => $self->xml_h()
	);
	
	$self->alert($alert);
	#call REST to check if auth key is valid
#	my $checkAuth = valAuthKey($alert->authkey(),$alert->srvSerial());
#	if($checkAuth eq '402'){
#		$tkLogger->info("Payment required for ".$self->sender().', '.$alert->authkey().', '.$alert->srvSerial());
#		return;
#	}
#	if($checkAuth eq '403'){
#		$tkLogger->info("Not a valid auth/serial combi: ".$self->sender().', '.$alert->authkey().', '.$alert->srvSerial());
#		return;
#	}
	my ($mysqlCfg,$DBCon) = $self->initMysql('alerts');
	
	#TODO Check when an email must be sent
	
	my ($ret,$fetchedStatus) = ALIsDuplicate($DBCon,$mysqlCfg->{'table'},$alert);
	#found a duplicate
	if($ret == 1){
		updateALDate($DBCon,$mysqlCfg->{'table'},$alert);
		$self->logger()->info("Found AL duplicate: ".$self->sender().', '.$alert->authkey());
	}
	#status differs, check if it is a recover
	if($ret == 2){
		#this is a recover, drop entry from duplicate DB
		if($alert->srvcStatus() eq 'OK' && $fetchedStatus ne 'OK'){
			delALDB($DBCon,$mysqlCfg->{'table'},$alert);
			$self->logger()->info("Deleting AL due to recover: ".$self->sender().', '.$alert->authkey());
		}
		else{
			#update the new status, keep entry
			updateALStatus($DBCon,$mysqlCfg->{'table'},$alert);
			$self->logger()->info("Updating AL status: ".$self->sender().', '.$alert->authkey());
		}
	}
	#AL not in DB
	if($ret == 0){
		insertAL($DBCon,$mysqlCfg->{'table'},$self->sender(),$alert);
		$self->logger()->info("Inserted new AL in DB: ".$self->sender().', '.$alert->authkey());
		#TODO Check if email must be sent, if yes call genALMail
		$self->genALMail();
	}
	if($ret == -1){
		$self->logger()->info("AL with same timestamp already in DB: ".$self->sender().', '.$alert->authkey());
	}
	closeConnection($DBCon);
	return;
}

sub genALMail{
	my $self = shift;
	#first copy the email
	$self->msg_plain(duplicateEmail($self->msg));
	#replace the body with decrypted XML
	replaceBody($self->msg_plain,$self->xml);
	#replace subject with alert ID string
	replaceSubject($self->msg_plain,$self->alert()->ID_str());
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
		sender => $ARGV[0],
		gpgCfg =>'../gnupg/GpgConfig.cfg',
		mysqlCfg => '../mysql/MysqlConfig.cfg',
		logCfg => '../filter/Logger.cfg'
	);
	try{
		$tkHandler->msg_str($msg_str);
		$tkHandler->parseMsgStr();
		$tkHandler->decryptXml();
	} catch{
		$tkLogger->emergency("Failed to parse mail and decrypt XML with: ".$_);
		exit(1);
	};
	
=head1 DESCRIPTION

Alert::Handler parses an email, exctracts the xml, parses the xml and
creates the corresponding objects (heartbeats, alerts). It is also responsible
for checking if these objects must be inserted/updated to the mysql database.

=head1 METHODS

=head2 new

Example:

	my $tkHandler = Alert::Handler->new(
		sender => $ARGV[0],
		gpgCfg =>'../gnupg/GpgConfig.cfg',
		mysqlCfg => '../mysql/MysqlConfig.cfg',
		logCfg => '../filter/Logger.cfg'
	);
	
Constructor - creates a new Handler object. As the Handler needs to decrypt,
connect to mysql and log three config files are required: 1. the gpg config
to have the private key password to decrypt the xml, 2. the mysql connection
credentials to write the objects to the duplicated database and 3. the logger
config to set corresponding logging paths.

=head2 sender

Get/set the sender of the email.

=head2 receiver

Get/set the receiver of the email.

=head2 gpgCfg

Get/set the gpg configuration file path.

=head2 mysqlCfg

Get/set the mysql configuration file path.

=head2 logCfg

Get/set the logger configuration file path.

=head2 logger

Get/set the TKlogger object, used to log Handler processing information.

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

Get/set the heartbeat object attribute.

=head2 alert

Get/set the alert object attribute.

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

Parse the xml from the email message, this returns an xml hash on success.
The email must be decrypted an parsed into body etc. before the xml can be parsed.

=head2 initMysql

Example:

	my ($mysqlCfg,$DBCon) = initMysql('heartbeats');
	
Establish a mysql connection and read out the given section of the
configuration file. The config file is assigned via the constructor
at Handler object creation.

=head2 handleHB

Example:

	try{
		$tkLogger->info("Xml type: ".$tkHandler->xmlType());
		my $ret = $tkHandler->handleHB();
	} catch{
		$tkLogger->emergency("Failed to handle HB with: ".$_);
	};
	
Handles a heartbeat object - checks if the auth key is valid, if the timestamp
must be updated in the database, if the alert can be deleted due to a service
recover, or if the alert is new and has to be inserted into the database.
Also loggs if an alert with the same timestamp is already in the dubplicate database.


=head2 handleAL

Example:

	try{
		my $ret = $tkHandler->handleAL();
	} catch{
		$tkLogger->emergency("Failed to handle AL with: ".$_);
	};
Handles an alert object - checks if the auth key is valid, if the timestamp
must be updated in the database or if the heartbeat has to be inserted into the
database. Also loggs if a heartbeat with the same timestamp is already in the
dubplicate database.

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Heartbeat requires a configuration file for

	-Decrypting the xml (gpgCfg)
	-Establish the mysql connection (mysqlCfg)
	-Setup correct logging (logCfg)

The paths to this files must be set when calling the Handler constructor.

=head1 DEPENDENCIES

	use Alert::Handler::Crypto;
	use Alert::Handler::Email;
	use Alert::Handler::Xml;
	use Alert::Handler::Dbase;
	use Alert::Handler::Validation;
	use Alert::Handler::TKLogger;
	use Alert::Handler::Heartbeat;
	use Alert::Handler::Alert;

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