use Alert::Handler::Xml;
use Alert::Handler::Validation;
use Data::Dumper;

MAIN:{
	
	my $hb_h = parseXmlFile('FilterAL.xml');
	print Dumper($hb_h);

	
	#test for a valid auth key
	print valAuthKey('9WNa8V2P86Q');
	print valAuthKey('r2XW84Nfi6v','9000091290');
	my $retCode = valAuthKey('r2XW84Nfi6v','9000091290');
}