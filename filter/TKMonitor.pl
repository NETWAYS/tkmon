#!/usr/bin/perl -w

use strict;
use warnings;

#Alert Handler modules to process emails
use Alert::Handler::Crypto;
use Alert::Handler::Email;
use Alert::Handler::Xml;

my $msg_str;
while(<STDIN>){
	$msg_str .= $_;
}

#parse the email
my $msg = parseEmailStr($msg_str);

#decrypt the body with a specified key
my $encBody_str = getBody($msg);
my $gpgConfig = readGpgCfg('../gnupg/GpgConfig.cfg');
my $xml_str = decrypt($encBody_str,$gpgConfig);

#assume for now it is a heartbeat
my $hb_h = parseXmlText($xml_str);

#As a first test print the heartbeat version
print getHBVersion($hb_h);


__END__

=head1 NAME

TKMonitor - A postfix after-queue filter to process incoming email.