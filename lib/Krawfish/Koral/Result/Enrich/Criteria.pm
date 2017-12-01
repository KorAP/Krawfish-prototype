package Krawfish::Koral::Result::Enrich::Criteria;
use strict;
use warnings;
use Role::Tiny::With;
use Scalar::Util qw/looks_like_number/;
use Krawfish::Util::String qw/binary_short/;

with 'Krawfish::Koral::Result::Inflatable';

# Enrich with sorting criteria, necessary
# for sorting on node and cluster level.


# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Key for enrichment
sub key {
  'sortedBy';
};


# Set a single sort criterion
sub criterion {
  my ($self, $level, $criterion) = @_;
  $self->[$level] = $criterion;
};


# Get unique doc identifier
sub uuid {

  # Get the last sort criterion
  # (is always the unique marker)
  $_[0]->[-1];
};

# Get number of levels
sub level_count {
  scalar @{$_[0]};
};


# Compare criteria
sub compare {
  my ($self, $with) = @_;

  for (my $i = 0; $i < $self->level_count; $i++) {

    # One level is undefined
    if (!$self->[$i] && !$with->[$i]) {
      if (!$self->[$i] && $with->[$i]) {
        return 1;
      }
      elsif ($self->[$i] && !$with->[$i]) {
        return -1;
      }
      $i++;
    }

    # Compare numerical level
    elsif (looks_like_number($self->[$i])) {

      if ($self->[$i] < $with->[$i]) {
        return -1;
      }

      elsif ($self->[$i] > $with->[$i]) {
        return 1;
      }

      else {
        $i++;
      };
    }

    # Compare string level
    else {
      if ($self->[$i] lt $with->[$i]) {
        return -1;
      }

      elsif ($self->[$i] gt $with->[$i]) {
        return 1;
      }

      else {
        $i++;
      };
    };
  };

  return -1;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = '';
  $str .= join(',', map { binary_short($_) } @$self);
  return $str;
};


# Serialize to KoralQuery
sub to_koral_fragment {
  # sortedBy : [
  #   {
  #     "@type" : "koral:field" # either numeric or binary
  #     ...
  #   },
  #   {
  #     "@type" : "koral:string"
  #     ...
  #   }
  # ]
  ...
};


# Inflate (nothing to do)
sub inflate {
  $_[0];
};


1;
