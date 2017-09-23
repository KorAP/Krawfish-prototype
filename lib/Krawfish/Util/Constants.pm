package Krawfish::Util::Constants;
use strict;
use warnings;
use Exporter 'import';

use constant {
  KEY_PREF   => '=', # ! Field keys
  FIELD_PREF => '/'  # + Field values
};

our @EXPORT_OK = (qw/KEY_PREF FIELD_PREF/);

our %EXPORT_TAGS = (
  PREFIX => [qw/KEY_PREF FIELD_PREF/]
);

1;
