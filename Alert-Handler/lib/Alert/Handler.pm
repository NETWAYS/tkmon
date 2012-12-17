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
		cfgPath => './Logger.cfg'
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

Alert::Handler - Work with TK-Monitoring emails

=head1 VERSION

This document describes Alert::Handler version 0.0.1

=head1 SYNOPSIS

Example: