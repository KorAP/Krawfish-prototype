package Krawfish::Result::Group::Classes;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   The name is somehow misleading, as this will only
#   group by surface terms.

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    segments   => shift, # Krawfish::Index::Segments object
    nrs => [@_],
    groups => {}
  }, $class;
};


# This will return a string, reflecting the group name of the list
sub get_group {
  my ($self, $match) = @_;

  # Get all classes from the match
  # Classes need to be sorted by start position
  # to be retrievable, in case the Segments-Stream
  # is implemented as a postingslist (probably not)
  my @classes = $self->get_classes_sorted($self->{nrs});

  my %class_group;

  # Classes have nr, start, end
  foreach my $class (@classes) {

    # WARNIG! CLASSES MAY OVERLAP SO SEGMENTS SHOULD BE CACHED OR BUFFERED!

    # Get start position
    my $start = $class->start;

    my @seq = ();

    # Receive segment
    my $seg = $segments->get($match->doc_id, $start);

    # Push term id to segment
    push (@seq, $seg->term_id);

    while ($start < $class->end -1) {
      $seg = $segments->get($match->doc_id, $start++);

      # Push term id to segment
      push (@seq, $seg->term_id);
    };

    $class_group{$class->nr} = join('|', @seq);
  };

  my $string = '';
  foreach (sort {$a <=> $b} keys %class_group) {
    $string .= $_ .':' . class_group{$_} . ';';
  };

  return $string;
};


1;
