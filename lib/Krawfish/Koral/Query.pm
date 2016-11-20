package Krawfish::Koral::Query;
use parent 'Krawfish::Info';
use Krawfish::Koral::Query::Builder;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    any => 0,
    optional => 0,
    null => 0,
    negative => 0,
    extended => 0,
    extended_left => 0,
    extended_right => 0
  }, $class;
};

#########################################
# Query Planning methods and attributes #
#########################################

# Prepare a query for an index
sub prepare_for {
  my ($self, $index) = @_;

  my $query = $self;

  # There is a possible 'any' extension,
  # that may exceed the text
  if ($self->is_extended_right) {
    my $builder = $self->builder;

    # Wrap query in a text element
    $query = $builder->position(
      ['endsWith', 'isAround', 'startsWith', 'matches'],
      $builder->span('base/s=t'),
      $self
    );
  };

  # Return the planned query
  # TODO: Check for serialization errors
  $query->plan_for($index);
};

# Plan a query for an index (to be overwritten)
sub plan_for;

sub is_any            { $_[0]->{any}            // 0 };
sub is_optional       { $_[0]->{optional}       // 0 };
sub is_null           { $_[0]->{null}           // 0 };
sub is_negative       { $_[0]->{negative}       // 0 };
sub is_extended_right { $_[0]->{extended_right} // 0 };
sub is_extended_left  { $_[0]->{extended_left}  // 0 };
sub is_extended       { $_[0]->is_extended_right || $_[0]->is_extended_left // 0 };
sub freq              { -1 };
sub type              { '' };

# TODO: Probably better to be renamed "potential_anchor"
sub maybe_anchor      {
  my $self = shift;
  return if $self->is_negative;
  return if $self->is_optional;
  return if $self->is_any;
  return 1;
};

# Check if the wrapped query may need to be sorted
# on focussing on a specific class.
# Normally spans are always sorted, but in case of
# a wrapped relation query, classed operands may
# be in arbitrary order. When focussing on these
# classes, the span has to me reordered.
sub maybe_unsorted { $_[0]->{maybe_unsorted} // 0 };

#############################
# Query Application methods #
#############################

# Deserialization of KoralQuery
sub from_koral {
  ...
};

# Overwritten
sub to_koral_fragment;

# Overwritten
sub to_string;

# Clone the query
# sub clone;

# Create KoralQuery builder
sub builder {
  return Krawfish::Koral::Query::Builder->new;
};

1;


__END__

