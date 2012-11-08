use Alert::Handler::Dbase;
use feature qw(say);

MAIN:{
	my $mysqlCfg = readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats');
	
	say $mysqlCfg->{'host'};
	say $mysqlCfg->{'db'};
	say $mysqlCfg->{'user'};
	
}