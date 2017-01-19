package Krawfish::Koral::Query;
use parent 'Krawfish::Info';
use Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Query::Importer;
use warnings;
use strict;

# TODO: Support filter - and analyze query tree to add filter to term-queries
# (That is probably more effective than filtering at the end!)

sub new {
  my $class = shift;
  my $self = bless {
    any => 0,
    optional => 0,
    null => 0,
    negative => 0,
    extended => 0,
    extended_left => 0,
    extended_right => 0
  }, $class;

  if ($_[0]) {
    return $self->from_koral(shift);
  };

  $self;
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
# TODO: Rename to_primitive(index)
sub plan_for;

# Filter a query based on a document query
sub filter_by;

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
# TODO: export this method from Importer
sub from_koral {
  my ($class, $kq) = @_;
  my $importer = Krawfish::Koral::Query::Importer->new;

  my $type = $kq->{'@type'};
  if ($type eq 'koral:group') {
    my $op = $kq->{operation};
    if ($op eq 'operation:sequence') {
      return $importer->seq($kq);
    }

    elsif ($op eq 'operation:class') {
      return $importer->class($kq);
    }
    else {
      warn 'Operation ' . $op . ' not supported';
    };
  }

  elsif ($type eq 'koral:token') {
    return $importer->token($kq);
  }
  else {
    warn $type . ' unknown';
  };

  return;
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

# Create KoralQuery builder
sub importer {
  return Krawfish::Koral::Query::Importer->new;
};

1;


__END__

