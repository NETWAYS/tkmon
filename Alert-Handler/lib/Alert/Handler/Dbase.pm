package Alert::Handler::Dbase;

use warnings;
use strict;
use Carp;
use DBI;
use Config::IniFiles;
use version;

use Alert::Handler::Converters;
use Alert::Handler::Alert;
use Alert::Handler::Heartbeat;

our $VERSION = qv('0.0.1');
our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(readMysqlCfg closeConnection getConnection insertHB HBIsDuplicate 
	updateHBDate updateHBDateContact updateHBDateSenderContact getHBDateDB getHBContactDB getHBSenderDB delHBDB insertAL 
	ALIsDuplicate getALValsDB updateALDate delALDB updateALStatus delDupsDB getEmailAdrDB);
	# symbols to export
}

sub readMysqlCfg{
	my $cfgPath = shift;
	my $section = shift;
	if(!defined($cfgPath) || !defined($section)){
		confess "Cannot use empty config path or empty section."
	}
	my %mysqlCfg;
	eval{
		tie %mysqlCfg, 'Config::IniFiles', (-file => $cfgPath);
	};
	if($@){
		confess "Could not read mysql config";
	}
	my %cfgSection =  %{$mysqlCfg{$section}};
	return \%cfgSection;
}

sub getConnection{
	my $mysqlCfg = shift;
	if(!defined($mysqlCfg)){
		confess "Cannot use undefined mysql config.";
	}
	my $DB = DBI->connect("DBI:mysql:".$mysqlCfg->{db}.";host=".$mysqlCfg->{host},
			$mysqlCfg->{user}, $mysqlCfg->{pwd}) ||
			die "Could not connect to database: $DBI::errstr";
	return $DB;
}

sub closeConnection{
	my $DB = shift;
	if(!defined($DB)){
		carp "Cannot close undefined mysql connection.";
	}
	else{
		$DB->disconnect;
	}
}

sub checkDB{
	my $DB = shift;
	my $DBTable = shift;
	if(!defined($DB)){
		confess "Cannot use undefined database handle";
	}
	if(!defined($DBTable)){
		confess "Cannot use undefined database table";
	}
}

sub insertHB{
	my $DB = shift;
	my $DBTable = shift;
	my $HBSender = shift;
	my $hb = shift;
	
	checkDB($DB,$DBTable);

	$hb->check();
	my $sth = $DB->prepare( "
			Insert INTO $DBTable
			(Sender_Email, Contact_Name, Version, Authkey, Date)
			VALUES (?, ?, ?, ?, ?)" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($HBSender,$hb->contactName(),$hb->version(),$hb->authkey(),strToMysqlTime($hb->date()))
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for inseting HB returned wrong count.";
	}
}

sub insertAL{
	my $DB = shift;
	my $DBTable = shift;
	my $ALSender = shift;
	my $alert = shift;
	
	checkDB($DB,$DBTable);

	$alert->check();
	my $sth = $DB->prepare( "
			Insert INTO $DBTable
			(Sender_Email, Contact_Name, TKmon_Active, Alert_Hash, Version, Authkey, Date, Host_Name, Host_IP,
			Host_OS, Srv_Serial, Comp_Serial, Comp_Name, Srvc_Name, Srvc_Status,
			Srvc_Output, Srvc_Perfdata, Srvc_Duration)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, INET_ATON(?), ?, ?, ?, ?, ?, ?, ?, ?, ?)" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
			
	my $rv = $sth->execute($ALSender,$alert->contactName(), $alert->tkmonActive(),$alert->alertHash(),$alert->version(),
			$alert->authkey(),strToMysqlTime($alert->date()),
			$alert->hostName(),$alert->hostIP(),$alert->hostOS(),$alert->srvSerial(),$alert->compSerial(),
			$alert->compName(),$alert->srvcName(),$alert->srvcStatus(),$alert->srvcOutput(),
			$alert->srvcPerfdata(),$alert->srvcDuration())
			or confess "Couldn't execute statement: " . $sth->errstr;
			
	if($rv != 1){
		confess "Affected rows for inseting AL returned wrong count.";
	}
}

sub HBIsDuplicate{
	my $DB = shift;
	my $DBTable = shift;
	my $HBSender = shift;
	my $hb = shift;
	
	checkDB($DB,$DBTable);
	
	$hb->check();
	#now check if date differs
	my $fetchedDate = getHBDateDB($DB,$DBTable,$hb->version(),$hb->authkey());

	#HB is not in table yet
	if(!defined($fetchedDate)){
		return 0;
	}
	#HB is in table, timestamp differs from given
	if($fetchedDate ne strToMysqlTime($hb->date())){
		#check if the sender differs 
		my $fetchedSender = getHBSenderDB($DB,$DBTable,$hb->version(),$hb->authkey());
		if(defined($fetchedSender) && ($HBSender ne $fetchedSender)){
			return 3;
		}
		#check if the contact differs 
		my $fetchedContact = getHBContactDB($DB,$DBTable,$hb->version(),$hb->authkey());
		if(defined($fetchedContact) && ($hb->contactName() ne $fetchedContact)){
			return 2;
		}
		return 1;
	}
	#HB is in table, with same timestamp, this should rather be rare
	if($fetchedDate eq strToMysqlTime($hb->date())){
		return -1;
	}
}

sub updateHBDate{
	my $DB = shift;
	my $DBTable = shift;
	my $hb = shift;
	
	checkDB($DB,$DBTable);
	
	$hb->check();
	my $sth = $DB->prepare( "
			UPDATE $DBTable
			SET Date = ?
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
			
	my $rv = $sth->execute(strToMysqlTime($hb->date()),$hb->version(),$hb->authkey())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for updating HB Date returned wrong count.";
	}
}

sub updateHBDateContact{
	my $DB = shift;
	my $DBTable = shift;
	my $hb = shift;
	
	checkDB($DB,$DBTable);
	
	$hb->check();
	my $sth = $DB->prepare( "
			UPDATE $DBTable
			SET Date = ?, Contact_Name = ?
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
			
	my $rv = $sth->execute(strToMysqlTime($hb->date()),$hb->contactName(),$hb->version(),$hb->authkey())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for updating HB Date and Contact returned wrong count.";
	}
}

sub updateHBDateSenderContact{
	my $DB = shift;
	my $DBTable = shift;
	my $HBSender = shift;
	my $hb = shift;
	
	checkDB($DB,$DBTable);
	
	$hb->check();
	my $sth = $DB->prepare( "
			UPDATE $DBTable
			SET Date = ?, Contact_Name = ?, Sender_Email = ?
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
			
	my $rv = $sth->execute(strToMysqlTime($hb->date()),$hb->contactName(),$HBSender,$hb->version(),$hb->authkey())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for updating HB Date and Contact returned wrong count.";
	}
}

sub delHBDB{
	my $DB = shift;
	my $DBTable = shift;
	my $HBVersion = shift;
	my $HBAuthkey = shift;

	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			DELETE FROM $DBTable
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($HBVersion,$HBAuthkey)
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for deleting HB returned wrong count.";
	}
}

sub getHBDateDB{
	my $DB = shift;
	my $DBTable = shift;
	my $HBVersion = shift;
	my $HBAuthkey = shift;

	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			SELECT Date
			FROM $DBTable
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($HBVersion,$HBAuthkey)
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	#the heartbeat is not in the table yet
	if($sth->rows == 0){
		return undef;
	}
	#more than 1 HB - duplicate checking has not worked correctly 
	if($sth->rows != 1){
		confess "Already a duplicate HB in DB.";
	}
	my $fetchedDate;
	$rv = $sth->bind_columns(\$fetchedDate);
	$sth->fetch;
	return $fetchedDate;
}

sub getHBContactDB{
	my $DB = shift;
	my $DBTable = shift;
	my $HBVersion = shift;
	my $HBAuthkey = shift;

	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			SELECT Contact_Name
			FROM $DBTable
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($HBVersion,$HBAuthkey)
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	#the heartbeat is not in the table yet
	if($sth->rows == 0){
		return undef;
	}
	#more than 1 HB - duplicate checking has not worked correctly 
	if($sth->rows != 1){
		confess "Already a duplicate HB in DB.";
	}
	my $fetchedContact;
	$rv = $sth->bind_columns(\$fetchedContact);
	$sth->fetch;
	return $fetchedContact;
}

sub getHBSenderDB{
	my $DB = shift;
	my $DBTable = shift;
	my $HBVersion = shift;
	my $HBAuthkey = shift;

	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			SELECT Sender_Email
			FROM $DBTable
			WHERE Version = ?
			AND Authkey = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($HBVersion,$HBAuthkey)
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	#the heartbeat is not in the table yet
	if($sth->rows == 0){
		return undef;
	}
	#more than 1 HB - duplicate checking has not worked correctly 
	if($sth->rows != 1){
		confess "Already a duplicate HB in DB.";
	}
	my $fetchedSender;
	$rv = $sth->bind_columns(\$fetchedSender);
	$sth->fetch;
	return $fetchedSender;
}

sub ALIsDuplicate{
	my $DB = shift;
	my $DBTable = shift;
	my $alert = shift;
	
	checkDB($DB,$DBTable);
	
	#now check if Alert differs
	my ($fetchedDate,$fetchedStatus) = getALValsDB($DB,$DBTable,$alert);
	
	#AL is not in table yet
	if(!defined($fetchedDate)){
		return 0;
	}
	#AL is in the table, date differs
	if(($alert->srvcStatus() eq $fetchedStatus) &&
		($fetchedDate ne strToMysqlTime($alert->date() ) )){
		return 1;
	}
	#TODO Check also if date differs? -> this would mean a different
	#service output for the same timestamp -> should not be possible
	#AL is in the table, status and date differs
	if($alert->srvcStatus() ne $fetchedStatus){
		return (2,$fetchedStatus);
	}
	#AL is in table, with same timestamp, this should rather be rare
	if( ($alert->srvcStatus() eq $fetchedStatus) &&
		( $fetchedDate eq strToMysqlTime($alert->date()) ) ){
		return -1;
	}
}

sub getALValsDB{
	my $DB = shift;
	my $DBTable = shift;
	my $alert = shift;

	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			SELECT Alert_Hash, Date, Srvc_Status
			FROM $DBTable
			WHERE Alert_Hash = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($alert->alertHash())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	#the alert is not in the table yet
	if($sth->rows == 0){
		return undef;
	}
	#more than 1 Alert - duplicate checking has not worked correctly 
	if($sth->rows != 1){
		confess "Already a duplicate AL in DB.";
	}
	my ($fetchedDate, $fetchedStatus);
	$rv = $sth->bind_col(2,\$fetchedDate);
	$rv = $sth->bind_col(3,\$fetchedStatus);
	$sth->fetch;
	return ($fetchedDate,$fetchedStatus);
}

sub delALDB{
	my $DB = shift;
	my $DBTable = shift;
	my $alert = shift;
	
	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			DELETE FROM $DBTable
			WHERE Alert_Hash = ?" )
			or confess "Couldn't prepare statement: " . $DB->errstr;
			
	my $rv = $sth->execute($alert->alertHash())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for deleting AL returned wrong count.";
	}
}

sub updateALDate{
	my $DB = shift;
	my $DBTable = shift;
	my $alert = shift;
	
	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			UPDATE $DBTable
			SET Date = ?
			WHERE Alert_Hash = ?")
			or confess "Couldn't prepare statement: " . $DB->errstr;
			
	my $rv = $sth->execute(strToMysqlTime($alert->date()),$alert->alertHash())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for updating AL Date returned wrong count.";
	}
}

sub updateALStatus{
	my $DB = shift;
	my $DBTable = shift;
	my $alert = shift;
	
	checkDB($DB,$DBTable);
	
	my $sth = $DB->prepare( "
			UPDATE $DBTable
			SET Srvc_Status = ?
			WHERE Alert_Hash = ?")
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute($alert->srvcStatus(),$alert->alertHash())
	or confess "Couldn't execute statement: " . $sth->errstr;
	
	if($rv != 1){
		confess "Affected rows for updating AL status returned wrong count.";
	}
}

sub delDupsDB{
	my $DB = shift;
	my $DBTable = shift;
	my $interval = shift;

	checkDB($DB,$DBTable);
	if(!defined($interval)){
		confess "Cannot use empty interval.";
	}
	if(!($interval =~ m/^[0-9]* [a-zA-Z]*$/)){
		confess "Given interval contains invalid characters.";
	}
	my $sth = $DB->prepare( "
			DELETE FROM $DBTable
			WHERE DATE < 
			DATE_SUB( NOW( ) , INTERVAL ".$interval." )")
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute()
	or confess "Couldn't execute statement: " . $sth->errstr;
}

sub getEmailAdrDB{
	my $DB = shift;
	my $DBTable = shift;
	my $interval = shift;

	checkDB($DB,$DBTable);
	if(!defined($interval)){
		confess "Cannot use empty interval.";
	}
	if(!($interval =~ m/^[0-9]* [a-zA-Z]*$/)){
		confess "Given interval contains invalid characters.";
	}
	my $sth = $DB->prepare( "
			SELECT Sender_Email FROM $DBTable
			WHERE DATE < 
			DATE_SUB( NOW( ) , INTERVAL ".$interval." )")
			or confess "Couldn't prepare statement: " . $DB->errstr;
	
	my $rv = $sth->execute()
	or confess "Couldn't execute statement: " . $sth->errstr;
	#nothing has been returned
	if($sth->rows == 0){
		return undef;
	}
	my ($fetchedMail);
	$rv = $sth->bind_col(1,\$fetchedMail);
	my @mailAdresses;
	while($sth->fetch){
		push @mailAdresses,$fetchedMail
	}
	return \@mailAdresses;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Dbase - Access mysql databases and work with Heartbeats and Alerts

=head1 VERSION

This document describes Alert::Handler::Dbase version 0.0.1

=head1 SYNOPSIS

Example

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
	closeConnection($DBCon);

=head1 DESCRIPTION

Alert::Handler::Dbase connects to a mysql database. The module is able to
insert and check Heartbeats and Alerts. In order to use the correct data format
for inserts and checks the module Alert::Handler::Converters can be used.

=head1 METHODS 

=head2 readMysqlCfg

Example:

	my $mysqlCfg = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');

Parses a mysql config file, see Config::IniFiles for config format. The second parameter 
is the corresponding section in the ini file that should be read out.
The function returns a hash containing the config parameters.

Example Config:

	[alerts]
	host = 192.168.56.101
	db = tk_monitoring
	table = Alerts
	user = root
	pwd = TOBEDEFINED

=head2 getConnection

Example:

	my $DBCon = getConnection($mysqlCfg);

Calls the DBI connect function and tries to connect to the mysql server. The host,
database, user and password must be specified in the config file which must be read by
readMysqlCfg before calling getConnection.
On Success returns a valid database handle else raises an error.

=head2 closeConnection

Example:

	closeConnection($DBCon);

Closes an open database connection by the given handle.

=head2 checkDB

Checks if the database parameters are defined.

=head2 insertHB

Example:

	insertHB($DBCon,$mysqlCfg->{'table'},$self->sender(),
		$heartbeat->version(),$heartbeat->authkey(),$heartbeat->date());

Inserts a new heartbeat into the given table. The database is specified by a valid
database handle. Parameters: Database handle, Database table, HB sender, HB version,
HB authkey, HB date. insertHB uses Alert::Handler::Converters to convert the date to
a mysql valid format.

=head2 insertAL

Example:

	insertAL($DBCon,$mysqlCfg->{'table'},$self->sender(),$alert);
		$self->logger()->info("Inserted new AL in DB: ".$self->sender().', '.$alert->authkey());

Inserts a new alert into the given table. The database is specified by a valid
database handle. Parameters: Database handle, Database table, alert object.
insertAL uses Alert::Handler::Converters to convert the date to a mysql valid format.

=head2 HBIsDuplicate

Example:

	$ret = HBIsDuplicate($DBCon,$mysqlCfg->{'table'},
		$heartbeat->version(),$heartbeat->authkey(),$heartbeat->date());

Checks if the given heartbeat (version, authkey, date) is already in the database.table.

Parameters:

	-DB Handle
	-Table name to check
	-The HB version
	-The HB authkey
	-The current date time

Return values:

	-'0' if the heartbeat is not in the database
	-'1' if the heartbeat is in the database but the date differs
	-'-1' if the heartbeat is in the database and has the same date

=head2 updateHBDate

Example:

	updateHBDate($DBCon,$mysqlCfg->{'table'},
		$heartbeat->date(),
		$heartbeat->version(),$heartbeat->authkey());

Updates the DATETIME column of a given heartbeat.

Parameters:

	-DB Handle
	-Table name to insert HB to
	-The new date time
	-The HB version
	-The HB authkey

=head2 delHBDB

Example:

	delHBDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey());
	
Deletes a heartbeat from the database.

=head2 getHBDate

	print getHBDate($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a");

Read out the date for the given heartbeat (version,authkey). Returns the date
as mysql string if succesfully read or undef if the authkey with its version
is not in the database.

=head2 ALIsDuplicate

Example:

	my ($ret,$fetchedStatus) = ALIsDuplicate($DBCon,$mysqlCfg->{'table'},$alert);

Checks if the given alert object is already in the database.table.

Parameters:

	-DB Handle
	-Table name to check
	-The alert object

Return values:

	-'0' if the alert is not in the database
	-'1' if the alert is in the database but the date differs
	-'2' if the alert is in the database but the service state differs
	-'-1' if the alert is in the database and has the same date
	
=head2 getALValsDB

Example:

	my ($fetchedDate,$fetchedStatus) = getALValsDB($DB,$DBTable,$alert);
	
Fetches date and state from the database. Parameters: Database handle,
Database table, alert object. Takes the alert unique hash value and fetches
the values from the database. If more than one alert is returned there is
already a duplicate in the database, so this should not happen.

=head2 delALDB

Example:

	delALDB($DBCon,$mysqlCfg->{'table'},$alert);
	
Delete the alert from the database.

=head2 updateALDate

Example:

	updateALDate($DBCon,$mysqlCfg->{'table'},$alert);

Update the date for the alert. Paramerters: Database handle, Database table,
alert object. As update the date from the alert object is taken.

=head2 updateALStatus

Example:

	updateALStatus($DBCon,$mysqlCfg->{'table'},$alert);

Update the service status for the alert. Paramerters: Database handle, Database table,
alert object. As update the service status from the alert object is taken.

=head2 delDupsDB

Example:

	my $interval = '1 Day';
	delDupsDB($DBCon,$mysqlCfg->{'table'},$interval);

Deletes all entries from the database table that are older than $interval.

=head2 getEmailAdrDB

Example:

	$interval = '50 Hour';
	my $mails = getEmailAdrDB($DBCon,$mysqlCfg->{'table'},$interval);

Fetches the email adress from entries whose date is older than $interval. Returns
an array reference containing all addresses.

=head1 DIAGNOSTICS

=over

=item C<< Cannot use empty config path or empty section. >>

The given path or section in readMysqlCfg is empty.

=item C<< Could not read mysql config. >>

Reading the config file with Config::IniFiles in readMysqlCfg returned an error.

=item C<< Cannot use undefined mysql config. >>

The config reference in getConnection is undefined.

=item C<< Could not connect to database: $DBI::errstr >>

The DBI connect function in getConnection returned an error.

=item C<< Cannot close undefined mysql connection. >>

The DB handle in closeConnection is undefined.

=item C<< Cannot use undefined database table. >>

The specified database table is undefined.

=item C<< Cannot use undefined database handle. >>

The specified database handle is undefined.

=item C<< Affected rows for inseting HB returned wrong count. >>

Inserting a heartbeat should only affect 1 row, this error signals
that the INSERT affected rows != 1.

=item C<< Warning - Already a duplicate HB in DB. >>

Checking for a duplicate heartbeat should return only 1 entry
when carrying out a SELECT. If SELECT returns more than one entry
than there is already a duplicate in the database.

=item C<< Cannot insert empty HB values to database. >>

One of the given parameters (version, authkey, date) for inserting
is undefined.

=item C<< Cannot select empty HB values from database. >>

One of the given parameters (version, authkey, date) for selecting
from the database is undefined.

=item C<< Affected rows for updating HB Date returned wrong count. >>

Updating a hearbeat date must update only one row.

=item C<< Failed to get AL values from DB with: >>

ALIsDuplicate could not fetch values from database.

=item C<< Warning - Already a duplicate AL in DB. >>

GetAlValsDB found more than one entry in the database with the given hash.
Therefore duplicate checking was not successful.

=item C<< Affected rows for deleting AL returned wrong count. >>

Deleting an Alert should only affect one database row.

=item C<< Affected rows for updating AL daate returned wrong count. >>

Updating an alert date should only affect one database row.

=item C<< Affected rows for updating AL status returned wrong count. >>

Updating an alert status should only affect one database row.

=item C<< Couldn't prepare statement: >>

Calling $DB-prepare returned an error.

=item C<< Couldn't execute statement: >>

Calling sql statement execute returned an error.

=item C<< Cannot use empty interval. >>

Deleting duplicates from the DB requires an interval to specify the entries older
than this parameter should be deleted.

=item C<< Given interval contains invalid characters. >>

Deleting duplicates checks the given interval: e.g. 1 Day, 24 Hours. Other
characters are not allowed.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Alert::Handler::Dbase requires one configuration file to
specify how to connect to the mysql server. Also the desired table
is specified in this file. A call to readMysqlCfg needs the
path to this file in order to parse the file and init the 
config hash.

=head1 DEPENDENCIES

	use warnings;
	use strict;
	use Carp;
	use DBI;
	use Config::IniFiles;
	use version;
	use Alert::Handler::Converters;
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