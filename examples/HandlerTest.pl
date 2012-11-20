use Alert::Handler;
use Alert::Handler::Xml;
use Try::Tiny;
use feature qw(say);

use Benchmark;

$t0 = Benchmark->new;
my $tkHandler = Alert::Handler->new(
	sender => 'tktest@example.com'
);

my $msg_str;
while(<STDIN>){
	$msg_str .= $_;
}
try{
	$tkHandler->msg_str($msg_str);
	$tkHandler->parseMsgStr();
	$tkHandler->gpgCfg('../gnupg/GpgConfig.cfg');
	$tkHandler->decryptXml();
} catch{
	say "Failed with: ".$_;
	exit(1);
};
my $hb_h = parseXmlText($tkHandler->xml());
say getHBVersion($hb_h);


$t1 = Benchmark->new;
$td = timediff($t1, $t0);
say "The code took:",timestr($td),"\n";