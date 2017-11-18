package Krawfish::Koral::Result::Enrich::Snippet::Milestone;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Log;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';
with 'Krawfish::Koral::Result::Enrich::Snippet::Annotation';

use constant DEBUG => 0;

# The milestone element always is embedded before
# the actual position

# Milestones have identical start and end positions
sub end {
  $_[0]->start;
};

1;
