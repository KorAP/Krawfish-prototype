package Krawfish::Koral::Result::Enrich::Snippet::Milestone;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Document::Annotation';
with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';
with 'Krawfish::Koral::Result::Enrich::Snippet::TUI';
with 'Krawfish::Koral::Result::Enrich::Snippet::Certainty';

use constant DEBUG => 0;

# The milestone element always is embedded before
# the actual position

# Milestones have identical start and end positions
sub end {
  $_[0]->start;
};

1;
