use Alert::Handler::Converters;
use Try::Tiny;
use feature qw(say switch);


MAIN:{

	my $dt = strToDateTime('Thu Oct 11 04:54:34 2012');
	print DateTimeToMysql($dt);
}