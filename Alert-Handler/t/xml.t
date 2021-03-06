#!/usr/bin/perl -w

use Test::More tests => 28;

use Alert::Handler::Xml;
use Alert::Handler::Heartbeat;
use Alert::Handler::Alert;

my $xml_str = '<?xml version="1.0" encoding="UTF-8"?>
<heartbeat version="0.1-dev">
	<authkey category="Monitoring">0123456789a</authkey>
	<contact-name>Jean</contact-name>
	<date>Thu Oct 11 04:54:34 2012</date>
</heartbeat>';

my $hb_h = parseXmlFile('../examples/HeartbeatTest.xml');
my $heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $hb_h
);
use Data::Dumper;
is(getXmlType($hb_h), 'heartbeat','xml type heartbeat');
is($heartbeat->version(), '0.1-dev','heartbeat version');
is($heartbeat->contactName(), 'Jean','hearbeat contact name');
is($heartbeat->date(), 'Thu Oct 11 04:54:34 2012','heartbeat date');
is($heartbeat->authkey(),'0123456789a','heartbeat auth key value');

undef $hb_h;
undef $heartbeat;
$hb_h = parseXmlText($xml_str);
$heartbeat = Alert::Handler::Heartbeat->new(
	xmlRoot => $hb_h
);
is(getXmlType($hb_h), 'heartbeat','xml type heartbeat');
is($heartbeat->version(), '0.1-dev','heartbeat version');
is($heartbeat->contactName(), 'Jean','hearbeat contact name');
is($heartbeat->date(), 'Thu Oct 11 04:54:34 2012','heartbeat date');
is($heartbeat->authkey(),'0123456789a','heartbeat auth key value');

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
	xmlRoot => $hb_h
);
is(getXmlType($hb_h), 'alert','xml type alert');
is($alert->version(), '0.1-dev','alert version');
is($alert->date(), 'Thu Oct 11 04:54:34 2012','alert date');
is($alert->contactName(), 'Jean','alert contact name');
is($alert->authkey(),'0123456789a','alert auth key value');
is($alert->hostName(),'tktest-host','alert host name');
is($alert->hostIP(),'192.168.1.1','alert host IP');
is($alert->hostOS(),'Ubuntu 12.04.1 LTS','alert host OS');
is($alert->srvSerial(),'9000088123','alert server serial');
is($alert->compSerial(),undef,'alert component serial');
is($alert->compName(),undef,'alert component name');
is($alert->srvcName(),'IPMI', 'alert service name');
is($alert->srvcStatus(),'OK', 'alert service status');
my $output = "IPMI Status: OK
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
PS Status = 'Presence detected' (Status: Nominal)";
is($alert->srvcOutput(),$output, 'alert service output');
$output = "'System Temp'=29.00 'Peripheral Temp'=38.00 'FAN 1'=1725.00 'Vcore'=0.74 '3.3VCC'=3.36 '12V'=11.93 'VDIMM'=1.53 '5VCC'=5.09 '-12V'=-12.09 'VBAT'=3.12 'VSB'=3.34 'AVCC'=3.38";
is($alert->srvcPerfdata(),$output, 'alert service perfdata output');
is($alert->srvcDuration(),'1.196 seconds','alert service duration');
is($alert->ID_str(),'9000088123-IPMI-OK','alert ID string');
is(unpack("H*",$alert->alertHash()),'4a5e560b1377603a2107c3b8bde60237a15a501c3c98f2e5c35454ef63963e9344cf284c07daad1548da36fa28174f03b82e46d3bab8deb182de9781ce375a53','alert sha512 hash');




