package Krawfish::Compile::Segment::Nowhere;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Query::Nowhere';
with 'Krawfish::Compile::Segment';


sub compile {
  return shift->result;
};

1;
