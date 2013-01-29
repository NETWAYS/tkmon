use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Alert::Handler',
    AUTHOR              => 'Georg Schönberger <gschoenberger@thomas-krenn.com>',
    VERSION_FROM        => 'lib/Alert/Handler.pm',
    ABSTRACT_FROM       => 'lib/Alert/Handler.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Crypt::GPG' => 0,
        'WWW::Curl::Easy' => 0,
        'XML::Bare' => 0,
        'Email::Simple' => 0,
        'Log::Dispatch' => 0,
        'Config::IniFiles' => 0,
        'Digest::SHA' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Alert-Handler-*' },
);
