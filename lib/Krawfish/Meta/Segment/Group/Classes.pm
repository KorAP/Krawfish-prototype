package Krawfish::Meta::Segment::Group::Classes;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   The name is somehow misleading, as this will only
#   group by surface terms.

# TODO:
#   Refer to Krawfish::Meta::Segment::TermIDs!

use constant {
  DEBUG => 0,
    NR => 0,
    START_POS => 1,
    END_POS => 2,
};


sub new {
  my $class = shift;
  bless {
    segment => shift,
    nrs => @_ ? [sort @_] : undef,
    groups => {},
  }, $class;
};


# Get the group signature for each match
sub get_group {
  my ($self, $match) = @_;

  # Get all classes from the match
  # Classes need to be sorted by start position
  # to be retrievable, in case the subtokens-Stream
  # is implemented as a postingslist (probably not)
  my @classes = $match->get_classes_sorted($self->{nrs});

  my $subtokens = $self->{segment}->subtokens;

  my %class_group;

  # Classes have nr, start, end
  foreach my $class (@classes) {

    # WARNING! CLASSES MAY OVERLAP SO SUBTOKENS SHOULD BE CACHED OR BUFFERED!

    # Get start position
    my $start = $class->[START_POS];

    my @seq = ();

    # Receive subtoken
    my $subt = $subtokens->get($match->doc_id, $start);

    # Push term id to subtoken
    # TODO: A subtoken should have accessors
    push (@seq, $subt->[2]);

    while ($start < ($class->[END_POS] -1)) {
      $subt = $subtokens->get($match->doc_id, ++$start);

      # Push subterm id to subtoken
      push (@seq, $subt->[2]);
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


# Return group info as hash
sub to_hash {
  my ($self, $signature, $doc_freq, $freq) = @_;

  # TODO:
  #   This can't work!
  # Get dictionary object to convert terms to term id
  # my $dict = $self->{segment}->dict;

  my %hash = ();
  while ($signature =~ /\G(\d+):(.+?);/g) {

  #  if (DEBUG) {
  #    print_log('g_class', "Build class $1 for signature $2");
  #  };

    $hash{"class_$1"} = [ split('___', $2)];
  };
  $hash{freq} = $freq if defined $freq;
  $hash{doc_freq} = $doc_freq;
  return \%hash;
};


sub to_string {
  my $str = 'classes';
  $str .= $_[0]->{nrs} ? '[' . join(',', @{$_[0]->{nrs}}) . ']' : '';
  return $str;
};

1;
