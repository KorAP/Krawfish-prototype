package Krawfish::Util::Constants;
use strict;
use warnings;
use Exporter 'import';

use constant {
  KEY_PREF     => '!',  # Field keys
  FIELD_PREF   => '+',  # Field values
  FOUNDRY_PREF => '^',  # Foundry
  LAYER_PREF   => '&',  # Layer
  SUBTERM_PREF => '.',  # * before
  TOKEN_PREF   => ':',  # Empty before
  SPAN_PREF    => '-',  # <> Spans before
  ATTR_PREF    => '@',
  REL_L_PREF   => '>',
  REL_R_PREF   => '<',
  PTI_CLASS    => 0     # Payload identifier for classes
};

our $ANNO_PREFIX_RE = qr/(?:\:|\-|\@|\>|\<)/;

our @EXPORT_OK = (qw/KEY_PREF
                     FIELD_PREF
                     FOUNDRY_PREF
                     LAYER_PREF
                     SUBTERM_PREF
                     TOKEN_PREF
                     SPAN_PREF
                     ATTR_PREF
                     REL_L_PREF
                     REL_R_PREF
                     PTI_CLASS
                     $ANNO_PREFIX_RE/);

our %EXPORT_TAGS = (
  PREFIX => [qw/KEY_PREF
                FIELD_PREF
                FOUNDRY_PREF
                LAYER_PREF
                SUBTERM_PREF
                TOKEN_PREF
                SPAN_PREF
                ATTR_PREF
                REL_L_PREF
                REL_R_PREF
                $ANNO_PREFIX_RE/],
  PAYLOAD => [qw/PTI_CLASS/]
);

1;
