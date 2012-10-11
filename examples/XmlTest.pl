use Alert::Handler::Xml;



MAIN:{
	
	my $hb_h = parseHBHash('HeartbeatTest.xml');
	print getHBVersion($hb_h);
}