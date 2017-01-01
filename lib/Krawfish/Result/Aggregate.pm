package Krawfish::Collection::Aggregate;
use parent 'Krawfish::Collection';
use Krawfish::Log;
use Krawfish::Posting::Match;
use strict;
use warnings;

# Aggregation queries will iterate through all matches
# And may make actions sometimes
# Warning: AVG as a single value won't work distributed!
#
# TODO: As aggregations only need unique IDs, it may be better to combine all
#   aggregations in one stream

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    op    => shift, # min, max, avg
    field => shift,
    count => 0,
    value => undef,
    doc_id => -1 # Aggregations need unique doc ids!
  }, $class;

  # Lift value list
  $self->{list} = $self->{index}->field_values($self->{field});

  if ($self->{op} eq 'min') {
    $self->{sub} = sub {
      $self->{value} = $self->{value} < $_[0] ? $_[0] : $self->{value};
    };
  }
  elsif ($self->{op} eq 'max') {
    $self->{sub} = sub {
      $self->{value} = $self->{value} > $_[0] ? $_[0] : $self->{value};
    };
  }
  elsif ($self->{op} eq 'sum') {
    $self->{sub} = sub {
      $self->{value} += $self->{value};
    };
  }
  elsif ($self->{op} eq 'count') {
    $self->{sub} = sub {
      $self->{count}++;
    };
  }
  elsif ($self->{op} eq 'avg') {
    $self->{sub} = sub {
      $self->{value} += $self->{value};
      $self->{count}++;
    };
  };

  return $self;
};


sub next {
  my $self = shift;

  my $values = $self->{list};
  my $value_current = $values->current;

  if ($self->{query}->next) {
    my $current = $self->{query}->current;

    # Doc was already counted
    return 1 if $current->doc_id == $self->{doc_id};
    $self->{doc_id} = $current->doc_id;

    # Current value has to catch up to the current doc
    if ($value_current->doc_id < $current->doc_id) {

      # Skip to doc id
      $value_current = $values->skip_to($current->doc_id);
    };

    # Check, if current value exists
    if ($current_value->doc_id == $current->doc_id) {
      $self->op($current_value->value);
    };

    return 1;
  };

  return 0;
};


sub op {
  $_[0]->{sub}->($_[1]);
};


sub current {
  return $_[0]->{query}->current;
};


sub aggregation {
  my $self = shift;
  if ($self->{op} eq 'avg') {
    return undef unless $self->{count};
    return $self->{value} / $self->{count};
  }
  elsif ($self->{op} eq 'count') {
    return $self->{count};
  };
  return $self->{value};
};


sub to_string {
  my $self = shift;
  my $str = 'aggr' . ucfirst($self->{op}) . '(';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;


__END__
