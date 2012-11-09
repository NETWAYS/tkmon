use Alert::Handler::Dbase;
use Alert::Handler::Converters;
use Try::Tiny;
use feature qw(say);


MAIN:{
	my $mysqlCfg = try{
		readMysqlCfg('../mysql/MysqlConfig.cfg','heartbeats')
	} catch{
		die "Failed with: $_";
	};
	say $mysqlCfg->{'host'};
	say $mysqlCfg->{'db'};
	say $mysqlCfg->{'table'};
	say $mysqlCfg->{'user'};

	my $DBCon = try{
		getConnection($mysqlCfg);
	} catch{
		die "Failed with: $_";
	};
	try{
		#insertHB($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a",strToMysqlTime("Thu Oct 11 04:54:34 2012"));
		if(HBIsDuplicate($DBCon,$mysqlCfg->{'table'},
			"0.1-dev","0123456789a",strToMysqlTime("Fri Nov 09 20:58:34 2012")) == 1){
			say "Found a duplicate: 0123456789a";
			updateHBDate($DBCon,$mysqlCfg->{'table'},
			strToMysqlTime("Fri Nov 09 20:58:34 2012"),"0.1-dev","0123456789a");
		};
		say "Fetched date from DB: ".getHBDate($DBCon,$mysqlCfg->{'table'},"0.1-dev","0123456789a");
	} catch{
		die "Failed with: $_";
	} finally{
		closeConnection($DBCon);
	};
	closeConnection($DBCon);
}