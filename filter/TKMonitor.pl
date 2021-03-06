#!/usr/bin/perl -w
use strict;
use warnings;
use Try::Tiny;
use IO::File;
use Carp;
use IPC::Run3;

use Alert::Handler;
use Alert::Handler::TKLogger;
use Alert::Handler::Email;

our $FILTER_DIR = "/etc/postfix/filter";
our $SENDMAIL = "/usr/sbin/sendmail";
our $MAILDIR = "/var/spool/tkmon";#temp dir to store mails

#Exit codes of commands invoked by postfix
our $TEMPFAIL = 75;
our $UNAVAILABLE = 69;

my $tkLogger = Alert::Handler::TKLogger->new(
		cfgPath => './Logger.cfg'
	);

#Start processing the email
my $msg_str;
while(<STDIN>){
	$msg_str .= $_;
}

#backup mail, keep filename to remove it at the end
#plaintext mail
my $fnamePT;
my $fname = try{
	saveMail($msg_str,$ARGV[0]);
} catch{
	$tkLogger->emergency("Failed to save mail with: ".$_);
	#TODO: Try to handle mail even without backup?
	exit(1);
};
#Setup up the Handler and decrypt the email
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
#Check if the email body is not empty
if(!defined($tkHandler->xml())){
	#Log which mail has been discarded
	$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded,
	no valid body found.");
	exit(0);
}

#We now have the decrypted XML from the body, now parse it
try{
	$tkHandler->parseXml();
} catch{
	$tkLogger->emergency("Failed to parse XML with: ".$_);
	exit(1);
};
#Check of which type the xml/mail is
if(!defined($tkHandler->xmlType()) ||
	( ($tkHandler->xmlType() ne 'heartbeat') &&
		($tkHandler->xmlType() ne 'alert'))){
	$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded.");
	exit(0);	
}
if($tkHandler->xmlType() eq 'heartbeat'){
	try{
		$tkLogger->info("Xml type: ".$tkHandler->xmlType());
		my $ret = $tkHandler->handleHB();
	} catch{
		$tkLogger->emergency("Failed to handle HB with: ".$_);
		$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded.");
		exit(1);
	};
	#check if mail has been generated
	if(defined($tkHandler->msg_plain())){
		#save the plaintext mail
		$fnamePT = try{
			saveMail(toString($tkHandler->msg_plain()),$tkHandler->sender(),$fname);
		} catch{
			$tkLogger->emergency("Failed to save PT mail with: ".$_);
		}
		#try to send an answer back to the sender
		try{
			my $msg = getBody($tkHandler->msg_plain());
			my $recv = $tkHandler->sender();
			my $mailToSend = {
				from => 'monitor@thomas-krenn.com',
				to => $recv,
				msg => $msg,
				subject => getSubject($tkHandler->msg_plain()),
				smtp => 'zimbra.thomas-krenn.com'
			};
			sendEmail($mailToSend);
			$tkLogger->info("Sent Email to: ".$tkHandler->sender());
		} catch{
			$tkLogger->emergency("Failed to send mail with: ".$_);
			$tkLogger->emergency("Email ".$fname." to ".$tkHandler->sender()." has not been sent.");
			exit(1);
		};
	}
}
if($tkHandler->xmlType() eq 'alert'){
	try{
		$tkLogger->info("Xml type: ".$tkHandler->xmlType());
		my $ret = $tkHandler->handleAL();
	} catch{
		$tkLogger->emergency("Failed to handle AL with: ".$_);
		$tkLogger->info("Email from: ".$tkHandler->sender()." has been discarded.");
		exit(1);
	};
	#check if mail has been generated
	if(defined($tkHandler->msg_plain())){
		#save the plaintext mail
		$fnamePT = try{
			saveMail(toString($tkHandler->msg_plain()),$tkHandler->sender(),$fname);
		} catch{
			$tkLogger->emergency("Failed to save PT mail with: ".$_);
		}
		try{
			sendMail(toString($tkHandler->msg_plain()));
		} catch{
			$tkLogger->emergency("Failed to send mail with: ".$_);
			$tkLogger->emergency("Email ".$fname." has not been sent.");
			exit(1);
		};
	}
}
#remove mail from spool
try{
	if(defined($fname)){
		delMail($fname);
	}
	if(defined($fnamePT)){
		delMail($fnamePT);
	}
} catch{
	$tkLogger->emergency("Failed to delete mail from spool with: ".$_);
	exit(1);
};

sub saveMail{
	my $mail_str = shift;
	my $sender = shift;
	my $fname = shift;
	
	#the first time of saving the filename is built
	if(!defined($fname)){
		my $time_str = scalar(localtime);
		$time_str =~ s/\s/\_/g;
		$fname = $MAILDIR.'/'.$sender.'-'.$time_str;
	}
	else{
		#the other time it is a plaintext mail
		$fname .= '-pt';
	}
	
	my $fh = new IO::File "> $fname";
	if(defined $fh){
		print $fh $mail_str;
		$fh->close;
	}
	else{
		confess "Could not save mail from ".$sender." to /var/spool/tkmon/".$fname;
	}
	return $fname;
}

sub delMail{
	my $fname = shift;
	unlink $fname or die $!;
}

sub sendMail{
	my $mail_str = shift;
	my @command = ($SENDMAIL,@ARGV);
	run3 \@command, \$mail_str;
}



__END__

=head1 NAME

TKMonitor - A postfix after-queue filter to process incoming email.