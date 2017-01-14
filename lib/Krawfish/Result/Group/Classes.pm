package Krawfish::Result::Group::Classes;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   The name is somehow misleading, as this will only
#   group by surface terms.

use constant {
  DEBUG => 0,
    NR => 0,
    START_POS => 1,
    END_POS => 2,
};

sub new {
  my $class = shift;
  bless {
    segments   => shift, # Krawfish::Index::Segments object
    nrs => @_ ? [sort @_] : undef,
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
  my @classes = $match->get_classes_sorted($self->{nrs});

  my $segments = $self->{segments};

  my %class_group;

  # Classes have nr, start, end
  foreach my $class (@classes) {

    # WARNING! CLASSES MAY OVERLAP SO SEGMENTS SHOULD BE CACHED OR BUFFERED!

    # Get start position
    my $start = $class->[START_POS];

    my @seq = ();

    # Receive segment
    my $seg = $segments->get($match->doc_id, $start);

    # Push term id to segment
    # TODO: A segment should have accessors
    push (@seq, $seg->[2]);

    while ($start < ($class->[END_POS] -1)) {
      $seg = $segments->get($match->doc_id, ++$start);

      # Push term id to segment
      push (@seq, $seg->[2]);
    };

    # Class not yet set
    unless ($class_group{$class->[NR]}) {
      $class_group{$class->[NR]} = join('___', @seq);
    }

    # There is a gap in the class, potentially an overlap!
    # TODO: Resolve overlaps!
    # TODO: Mark gaps!
    else {
      $class_group{$class->[NR]} .= '___' . join('___', @seq);
    };
  };

  my $string = '';
  foreach (sort {$a <=> $b} keys %class_group) {
    $string .= $_ .':' . $class_group{$_} . ';';
  };

  return $string;
};


sub to_string {
  my $str = 'classes';
  $str .= $_[0]->{nrs} ? '[' . join(',', @{$_[0]->{nrs}}) . ']' : '';
  return $str;
};

1;
