use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Alert::Handler::Crypto',
    AUTHOR              => 'Georg Schönberger <gschoenberger@thomas-krenn.com>',
    VERSION_FROM        => 'lib/Alert/Handler/Crypto.pm',
    ABSTRACT_FROM       => 'lib/Alert/Handler/Crypto.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Crypt::GPG' => 0,
        'Safe' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Alert-Handler-*' },
);
