use Alert::Handler::Xml;
use Alert::Handler::Validation;



MAIN:{
	
	my $hb_h = parseXmlHash('HeartbeatTest.xml');
	print getHBVersion($hb_h)."\n";
	print getHBDate($hb_h)."\n";
	my $authKey = getHBAuthKey($hb_h);
	
	#test for a valid auth key
	print valAuthKey('9WNa8V2P86Q');
	print valAuthKey('r2XW84Nfi6v','9000091290');
	my $retCode = valAuthKey('r2XW84Nfi6v','9000091290');
}