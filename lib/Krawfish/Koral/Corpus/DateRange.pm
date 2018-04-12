package Krawfish::Koral::Corpus::DateRange;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

# TODO:
#   In https://home.apache.org/~hossman/spatial-for-non-spatial-meetup-20130117/ there is support for
#   - doc duration intersects with query duration
#   - doc duration overlaps with query duration
#   - doc duration is within with query duration


sub type {
  'dateRange'
};

sub new {
  my $class = shift;

  my ($first, $second) = @_;

  if ($first->key ne $second->key ||
        $first->key_type ne $second->key_type ||
        $first->key_type ne 'date'
      ) {
    warn $first->to_string . ' and ' . $second->to_string . ' are incompatible for daterange';
    # TODO: Add error to report type!
  };

  return bless {
    first => $first,
    second => $second,
  }, $class;
};

# Turn the date range query into an or-query
sub normalize {
  my $self = shift;

  my @terms;
  if ($self->{first}) {
    push @terms, $self->{first}->to_query_terms;
  };

  # TODO:
  #   Return or-query
  return $self;
};


# stringify range query
sub to_string {
  my $self = shift;

  return 0 if $self->is_null;

  my $str = '';
  $str .= $self->{first}->key;

  $str .= '&=';

  $str .= '[';

  my ($first, $second) = ($self->{first}, $self->{second});

  if ($first->is_inclusive) {
    $str .= '[' . $first->value_string;
  }
  else {
    $str .= $first->value_string . '[';
  };

  $str .= '--';

  if ($second) {

    if ($second->is_inclusive) {
      $str .= $second->value_string . ']';
    }
    else {
      $str .= ']' . $second->value_string;
    };
  };
  return $str . ']';
};


sub from_koral { ... };

sub to_koral_fragment { ... };

sub optimize { ... };

1;
