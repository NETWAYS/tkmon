#!/usr/bin/perl -w

use Test::More tests => 47;

use Alert::Handler::Dbase;
use Alert::Handler::Xml;
use Alert::Handler::Heartbeat;
use Alert::Handler::Converters;

my $cfg = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');

is($cfg->{'host'}, '192.168.56.101');
is($cfg->{'db'}, 'tk_monitoring');
is($cfg->{'table'}, 'Heartbeats');
is($cfg->{'user'}, 'root');
my $con = getConnection($cfg);
ok($con,'mysql connection');

my $xml_str = '<?xml version="1.0" encoding="UTF-8"?>
<heartbeat version="0.1-dev">
	<authkey category="Monitoring">0123456789a</authkey>
	<contact-name>Jean</contact-name>
	<date>Thu Oct 11 04:54:34 2012</date>
</heartbeat>';
my $hb_h = parseXmlText($xml_str);
my $heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $hb_h
);

is(HBIsDuplicate($con,$cfg->{'table'},'test@example.com',$heartbeat),0,'HB not in DB');
is(insertHB($con,$cfg->{'table'},'test@example.com',$heartbeat),'','inserting HB to DB');
is(getHBDateDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	strToMysqlTime('Thu Oct 11 04:54:34 2012'),'fetching HB Date');
is(HBIsDuplicate($con,$cfg->{'table'},'test@example.com',$heartbeat),-1,'HB duplicate with same timestamp');
$heartbeat->date('Fri Oct 12 04:54:34 2012');
is(updateHBDate($con,$cfg->{'table'},$heartbeat),'','updating HB date');
is(getHBDateDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	strToMysqlTime('Fri Oct 12 04:54:34 2012'),'fetching modified HB Date');

$heartbeat->date('Thu Oct 11 04:54:34 2012');
is(HBIsDuplicate($con,$cfg->{'table'},'test@example.com',$heartbeat),1,'HB with timestamp differs');
is(getHBContactDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	'Jean','fetching HB contact');
$heartbeat->contactName('Jean Luc');
is(HBIsDuplicate($con,$cfg->{'table'},'test@example.com',$heartbeat),2,'HB with timestamp and contact differs');
is(updateHBDateContact($con,$cfg->{'table'},$heartbeat),'','updating HB date and contact');
is(getHBContactDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	'Jean Luc','fetching modified HB contact');

$heartbeat->date('Fri Oct 12 04:54:34 2012');
is(getHBSenderDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	'test@example.com','fetching HB sender');
is(HBIsDuplicate($con,$cfg->{'table'},'test2@example.com',$heartbeat),3,'HB with timestamp, contact and sender differs');
$heartbeat->contactName('Jean Luc Picard');
is(updateHBDateSenderContact($con,$cfg->{'table'},'test2@example.com',$heartbeat),'','updating HB date, contact and sender');	
is(getHBSenderDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	'test2@example.com','fetching modified HB sender');
is(getHBContactDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	'Jean Luc Picard','fetching modified HB contact');	
is(getHBDateDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),
	strToMysqlTime('Fri Oct 12 04:54:34 2012'),'fetching modified HB Date');
	
my $list = getEmailAdrDB($con,$cfg->{'table'},'1 Day');
is($list->[0],'test2@example.com','fetching email list');
is(delHBDB($con,$cfg->{'table'},$heartbeat->version(),$heartbeat->authkey()),'','deleting HB from DB');
ok(closeConnection($con),'close HB mysql connection');

#testing alert methods
$xml_str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<alert version=\"0.1-dev\">
	<authkey category=\"Monitoring\">0123456789a</authkey>
	<date>Thu Oct 11 04:54:34 2012</date>
	<contact-name>Jean</contact-name>
	<host>
		<name><![CDATA[tktest-host]]></name>
		<ip><![CDATA[192.168.1.1]]></ip>
		<operating-system><![CDATA[Ubuntu 12.04.1 LTS]]></operating-system>
		<server-serial><![CDATA[9000088123]]></server-serial>
	</host>
	<service>
		<name><![CDATA[IPMI]]></name>
		<status><![CDATA[OK]]></status>
		<plugin-output><![CDATA[IPMI Status: OK
System Temp = 29.00 (Status: Nominal)
Peripheral Temp = 38.00 (Status: Nominal)
CPU Temp = 'Low' (Status: Nominal)
FAN 1 = 1725.00 (Status: Nominal)
Vcore = 0.74 (Status: Nominal)
3.3VCC = 3.36 (Status: Nominal)
12V = 11.93 (Status: Nominal)
VDIMM = 1.53 (Status: Nominal)
5VCC = 5.09 (Status: Nominal)
-12V = -12.09 (Status: Nominal)
VBAT = 3.12 (Status: Nominal)
VSB = 3.34 (Status: Nominal)
AVCC = 3.38 (Status: Nominal)
Chassis Intru = 'OK' (Status: Nominal)
PS Status = 'Presence detected' (Status: Nominal)]]></plugin-output>
		<perfdata><![CDATA['System Temp'=29.00 'Peripheral Temp'=38.00 'FAN 1'=1725.00 'Vcore'=0.74 '3.3VCC'=3.36 '12V'=11.93 'VDIMM'=1.53 '5VCC'=5.09 '-12V'=-12.09 'VBAT'=3.12 'VSB'=3.34 'AVCC'=3.38]]></perfdata>
		<duration><![CDATA[1.196 seconds]]>	</duration>
		<component-serial />
		<component-name />
	</service>
</alert>";
$hb_h = parseXmlText($xml_str);
my $alert = Alert::Handler::Alert->new(
	xmlRoot => $hb_h,
	tkmonActive => 0
);
$cfg = readMysqlCfg('../mysql/MysqlConfig.cfg','alerts');
is($cfg->{'host'}, '192.168.56.101');
is($cfg->{'db'}, 'tk_monitoring');
is($cfg->{'table'}, 'Alerts');
is($cfg->{'user'}, 'root');
$con = getConnection($cfg);
ok($con,'mysql connection');

is(ALIsDuplicate($con,$cfg->{'table'},$alert),0,'AL not in DB');
is(insertAL($con,$cfg->{'table'},'test2@example.com',$alert),'','inserting AL to DB');
my ($fetchedDate,$fetchedStatus) = getALValsDB($con,$cfg->{'table'},$alert);
is($fetchedDate,strToMysqlTime('Thu Oct 11 04:54:34 2012'),'fetching AL date');
is($fetchedStatus,'OK','fetching AL status');
is(ALIsDuplicate($con,$cfg->{'table'},$alert),-1,'AL duplicate with same timestamp');
#set a new date
$alert->date('Sat Oct 13 10:54:34 2012');
is(ALIsDuplicate($con,$cfg->{'table'},$alert),1,'AL with timestamp differs');
is(updateALDate($con,$cfg->{'table'},$alert),'','Updating AL date');
is(ALIsDuplicate($con,$cfg->{'table'},$alert),-1,'AL duplicate with same timestamp');
($fetchedDate,$fetchedStatus) = getALValsDB($con,$cfg->{'table'},$alert);
is($fetchedDate,strToMysqlTime('Sat Oct 13 10:54:34 2012'),'fetching AL date');
#set a new service status
$alert->srvcStatus('Warning');
my $ret;
($ret,$fetchedStatus) = ALIsDuplicate($con,$cfg->{'table'},$alert); 
is($ret,2,'AL with service status differs');
is(updateALStatus($con,$cfg->{'table'},$alert),'','Updating AL status');
is(ALIsDuplicate($con,$cfg->{'table'},$alert),-1,'AL duplicate with same timestamp');
($fetchedDate,$fetchedStatus) = getALValsDB($con,$cfg->{'table'},$alert);
is($fetchedDate,strToMysqlTime('Sat Oct 13 10:54:34 2012'),'fetching AL date');
is($fetchedStatus,'Warning','fetching AL status');
$list = getEmailAdrDB($con,$cfg->{'table'},'1 Day');
is($list->[0],'test2@example.com','fetching email list');

is(delALDB($con,$cfg->{'table'},$alert),'','deleting AL from DB');
ok(closeConnection($con),'close AL mysql connection');