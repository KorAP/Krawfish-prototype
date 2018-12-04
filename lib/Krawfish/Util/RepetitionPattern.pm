package Krawfish::Util::RepetitionPattern;
use Krawfish::Log;
use strict;
use warnings;

# Create a vector of bits to check for valid repetitions.
# Used by Extension queries, to support patterns like
# []{2}{1,3}
# May also be useful for repetition queries and
# distance constraints.

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $ranges = [@_];

  my @vector = ();

  my $card = 0;
  my ($min, $max) = (100_000, 0);
  foreach (_set(\@_, 0)) {
    unless ($vector[$_]) {
      $min = $_ if $_ < $min;
      $max = $_ if $_ > $max;
      $vector[$_] = 1;
      $card++;
    };

    print_log('util_repp', 'Found ' . $_) if DEBUG;
  };

  return bless {
    ranges => $ranges,
    min => $min,
    max => $max,
    finger => 0,
    vector => \@vector,
    card => $card
  }, $class;
};


sub ranges {
  $_[0]->{ranges}
};

# Private setting routine
sub _set {
  my $list = shift;
  my $depth = shift;

  return (1) unless defined $list->[0];

  my $factor = shift @$list;

  my @result = ();
  # print_log('util_repp', "Check in range") if DEBUG;
  foreach my $v (_set($list, $depth+1)) {
    foreach my $f ($factor->[0] .. ($factor->[1] // $factor->[0])) {
      # print_log('util_repp', "Multiply $f and $v in $depth") if DEBUG;
      push @result, $f * $v;
    };
  };

  return @result;
};


# Check if a repetition of the any symbol is valid
sub check {
  my $self = shift;
  my $pos = shift;
  return $self->{vector}->[$pos];
};


sub min {
  $_[0]->{min};
};


sub max {
  $_[0]->{max};
};

sub cardinality {
  $_[0]->{card}
};

sub to_string {
  join(';', map { $_->[0] . '-' . $_->[1] } @{$_[0]->{ranges}});
};

1;
