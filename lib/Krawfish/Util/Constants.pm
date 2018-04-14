package Krawfish::Util::Constants;
use strict;
use warnings;
use Exporter 'import';

use constant {
  KEY_PREF        => '!',  # Field keys
  FIELD_PREF      => '+',  # Field values
  DATE_FIELD_PREF => '+',  # Field values (may differ)
  INT_FIELD_PREF  => '+',  # Field values (may differ)
  FOUNDRY_PREF    => '^',  # Foundry
  LAYER_PREF      => '&',  # Layer
  SUBTERM_PREF    => '.',  # * before
  TOKEN_PREF      => ':',  # Empty before
  SPAN_PREF       => '-',  # <> Spans before
  ATTR_PREF       => '@',
  REL_L_PREF      => '>',
  REL_R_PREF      => '<',
  RANGE_ALL_POST  => ']',
  RANGE_PART_POST => '[',
  RANGE_SEP       => '--',
  PTI_CLASS       => 0,    # Payload identifier for classes
  NOMOREDOCS      => 4_294_967_295, # (maximum value for 32 bit)
  MAX_TOP_K       => 4_294_967_295,
  MAX_SPAN_SIZE   => 4_294_967_295,
  MAX_CLASS_NR    => 15
};

our $ANNO_PREFIX_RE = qr/(?:\:|\-|\@|\>|\<)/;

our @EXPORT_OK = (qw/KEY_PREF
                     FIELD_PREF
                     DATE_FIELD_PREF
                     INT_FIELD_PREF
                     FOUNDRY_PREF
                     LAYER_PREF
                     SUBTERM_PREF
                     TOKEN_PREF
                     SPAN_PREF
                     ATTR_PREF
                     REL_L_PREF
                     REL_R_PREF
                     PTI_CLASS
                     $ANNO_PREFIX_RE
                     NOMOREDOCS
                     MAX_TOP_K
                     MAX_SPAN_SIZE
                     MAX_CLASS_NR
                     RANGE_ALL_POST
                     RANGE_PART_POST
                     RANGE_SEP/);

our %EXPORT_TAGS = (
  PREFIX => [qw/KEY_PREF
                FIELD_PREF
                DATE_FIELD_PREF
                INT_FIELD_PREF
                FOUNDRY_PREF
                LAYER_PREF
                SUBTERM_PREF
                TOKEN_PREF
                SPAN_PREF
                ATTR_PREF
                REL_L_PREF
                REL_R_PREF
                $ANNO_PREFIX_RE/],
  PAYLOAD => [qw/PTI_CLASS/],
  RANGE   => [qw/RANGE_ALL_POST
                 RANGE_PART_POST
                 RANGE_SEP/]
);

1;
