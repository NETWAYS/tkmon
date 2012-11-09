package Alert::Handler::Dbase;

use warnings;
use strict;
use Carp;
use DBI;
use Config::IniFiles;
use version;

our $VERSION = qv('0.0.1');
our (@ISA, @EXPORT);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(readMysqlCfg closeConnection getConnection insertHB HBIsDuplicate); # symbols to export
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
	my %section =  %{$mysqlCfg{$section}};
	return \%section;
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

sub insertHB{
	my $DB = shift;
	my $DBTable = shift;
	my $HBVersion = shift;
	my $HBAuthkey = shift;
	my $HBDate = shift;
	
	if(!defined($DB)){
		confess "Cannot use undefined database handle";
	}
	if(!defined($DBTable)){
		confess "Cannot use undefined database table";
	}
	if(!defined($HBVersion) ||
		!defined($HBAuthkey) ||
		!defined($HBDate)){
			confess "Cannot insert empty HB values to database.";
		}
	my $sth = $DB->prepare( "
			Insert INTO $DBTable
			(Version, Authkey, Date)
			VALUES (?, ?, ?)" );
	my $rv = $sth->execute($HBVersion,$HBAuthkey,$HBDate);
	if($rv != 1){
		confess "Affected rows for inseting HB returned wrong count.";
	}
}

sub HBIsDuplicate{
	my $DB = shift;
	my $DBTable = shift;
	my $HBVersion = shift;
	my $HBAuthkey = shift;
	my $HBDate = shift;
	
	if(!defined($DB)){
		confess "Cannot use undefined database handle";
	}
	if(!defined($DBTable)){
		confess "Cannot use undefined database table";
	}
	if(!defined($HBVersion) ||
		!defined($HBAuthkey) ||
		!defined($HBDate)){
			confess "Cannot select empty HB values from database.";
		}
	my $sth = $DB->prepare( "
			SELECT Date
			FROM $DBTable
			WHERE Version = ?
			AND Authkey = ?" );
	my $rv = $sth->execute($HBVersion,$HBAuthkey);
	#mor than 1 HB - duplicate checking has not worked correctly 
	if($sth->rows != 1){
		croak "Warning: Already a duplicate HB in DB."
	}
	my $fetchedDate;
	# Bind Perl variables to columns:
	$rv = $sth->bind_columns(\$fetchedDate);
	$sth->fetch;
	
	#we have found a duplicate
	if($fetchedDate eq $HBDate){
		return 1;
	}
	else{
		return 0;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Alert::Handler::Dbase - Access mysql databases and work with Heartbeats and Alerts


=head1 VERSION

This document describes Alert::Handler::Dbase version 0.0.1

=head1 SYNOPSIS

Example

	use Alert::Handler::Dbase;
	use Alert::Handler::Converters;
	my $mysqlCfg = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');
	my $DBCon = getConnection($mysqlCfg);
	insertHB($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a",strToMysqlTime("Thu Oct 11 04:54:34 2012"));
	if(HBIsDuplicate($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a",strToMysqlTime("Thu Oct 11 04:54:34 2012"))){
		say "Found a duplicate: 0123456789a";
	}
	closeConnection($DBCon);
  
=head1 DESCRIPTION

Alert::Handler::Dbase connects to a mysql database. The module is able to
insert and check Heartbeats and Alerts. In order to use the correct data format
for inserts the module Alert::Handler::Converters is usable.

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

=head2 insertHB

Example:

	insertHB($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a",strToMysqlTime("Thu Oct 11 04:54:34 2012"));

Inserts a new heartbeat into the given table. The database is specified by a valid
database handle. Parameters: Database handle, Database table, HB version, HB authkey, HB date
Use Alert::Handler::Converters (strToMysqlTime) to convert date formats.

=head2 HBIsDuplicate

Example:

	if(HBIsDuplicate($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a",strToMysqlTime("Thu Oct 11 04:54:34 2012"))){
		say "Found a duplicate: 0123456789a";
	}

Checks if the given heartbeat (version, authkey, date) is already in the database.table. If yes '1' is
returned signaling true, else '0' signaling false.

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

=item C<< Warning: Already a duplicate HB in DB. >>

Checking for a duplicat heartbeat should return only 1 entry
when carrying out a SELECT. If SELECT returns more than one entry
than there is already a duplicate in the database.

=item C<< Cannot insert empty HB values to database. >>

One of the given parameters (version, authkey, date) for inserting
is undefined.

=item C<< Cannot select empty HB values from database. >>

One of the given parameters (version, authkey, date) for selecting
from the database is undefined.

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
