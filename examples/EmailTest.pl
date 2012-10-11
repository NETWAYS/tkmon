use Alert::Handler::Crypto;



MAIN:{
	
	open FILE, "<", $ARGV[0] or die $!;
	my $config = readGpgCfg('../gnupg/GpgConfig.cfg');
	
	my $encrypted;
	while (<FILE>){
 		$encrypted .= $_;
	}
	$plaintext = decrypt($encrypted,$config);
	print $plaintext;
}
