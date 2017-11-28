package Krawfish::Index::Fields::Plain;
use strict;
use warnings;

# Collect field values and doc_ids
# before sorting in rank order

# Constructor
sub new {
  my $class = shift;
  bless {
    collation => shift,
    sorted => 1,
    list => []
  }, $class;
};


# Add new value doc_id pair
sub add {
  my ($self, $value, $doc_id) = @_;

  # TODO:
  #   Request the type of a collation, to support
  #   numerical, numerical range, date, date range,
  #   and string collations.

  my $coll = $self->{collation};

  # Collation is numerical
  if ($coll eq 'NUM') {
    push @{$self->{list}}, [$value, $doc_id];
  }

  # Collation is numerical with range
  elsif ($coll eq 'NUMRANGE' || $coll eq 'DATERANGE') {

    # TODO:
    #   Not yet implemented
    my ($min, $max) = $coll->min_max($value);
    push @{$self->{list}}, [$min, $doc_id];
    push @{$self->{list}}, [$max, $doc_id];
  }

  # Collation is a date
  elsif ($coll eq 'DATE') {

    # TODO:
    #   Not yet implementated
    my $date = $coll->date_num($value);
    push @{$self->{list}}, [$date, $doc_id];

  }

  # Use collation
  else {

    # Add sortkey to plain
    push @{$self->{list}}, [$coll->sort_key($value), $doc_id];
  };


  $self->{sorted} = 0;
};


# Get the collation
sub collation {
  $_[0]->{collation}
};

sub to_sorted {
  my $self = shift;
  $self->{collation} eq 'NUM' ?
    _numsort_fields($self->{list}) :
    _alphasort_fields($self->{list});
};


# This should depend on collation
sub _alphasort_fields {
  my $plain = shift;

  return sort { $a->[0] cmp $b->[0] } @$plain;
};


# Numerical sorting
sub _numsort_fields {
  my $plain = shift;

  # Or sort numerically
  return sort { $a->[0] <=> $b->[0] } @$plain;
};


# Stringification
sub to_string {
  my $self = shift;
  join('', map { '[' . join(',',@$_) . ']' } @{$self->{list}});
};


1;
