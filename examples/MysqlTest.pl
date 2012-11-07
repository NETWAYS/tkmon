use Alert::Handler::Dbase;
use feature qw(say);

MAIN:{
	my $mysqlCfg = readMysqlCfg("../mysql/MysqlConfig.cfg");
	
	say $mysqlCfg->{'heartbeats'}{'host'};
	say $mysqlCfg->{'heartbeats'}{'db'};
	say $mysqlCfg->{'heartbeats'}{'user'};
	
}