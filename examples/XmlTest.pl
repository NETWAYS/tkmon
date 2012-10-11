use Alert::Handler::Xml;



MAIN:{
	
	my $hb_h = parseXmlHash('HeartbeatTest.xml');
	print getHBVersion($hb_h)."\n";
	print getHBDate($hb_h)."\n";
	my $authKey = getHBAuthKey($hb_h);
	use Data::Dumper;
	print Dumper(%$authKey);
}