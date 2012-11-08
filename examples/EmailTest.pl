use Alert::Handler::Crypto;
use Try::Tiny;
use feature qw(say switch);


MAIN:{
	
	#open FILE, "<", $ARGV[0] or die $!;
	try{
		my $config = readGpgCfg('../gnupg/GpgConfig.cfg');
	} catch{
		say "Reading config died with: @_";
	}
	#my $encrypted;
	#while (<FILE>){
 	#	$encrypted .= $_;
	#}
	my $plaintext = decrypt($encrypted,$config);
	#print $plaintext;
}
