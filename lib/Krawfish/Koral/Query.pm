package Krawfish::Koral::Query;
use parent 'Krawfish::Info';
# TODO: Use the same parent as Koral::Corpus
use Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Query::Importer;
use Mojo::Util qw/md5_sum/;
use warnings;
use strict;

# TODO:
#   - rename 'nothing' to 'nowhere'
#   - rename 'any' to 'anywhere'
#   - extended_* may be queried
#     automatically without parameter

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

sub plan_for_new {
  my ($self, $index) = @_;
  $self
    ->normalize
    ->finalize
    ->refer
    ->inflate($index->dict)
    ->cache
    ->optimize($index);
};

# Normalize the query
sub normalize;


# Refer to common subqueries
sub refer {
  $_[0];
};


# Expand regular expressions ...
sub inflate;


# Check for cached subqueries
sub cache {
  $_[0];
};


# Optimize for an index
sub optimize;


# This is the class to be overwritten
# by subclasses
sub _finalize {
  $_[0];
};

sub finalize {
  my $self = shift;

  my $query = $self;

  if ($query->is_any || $query->is_null) {
    $self->error(780, "This query matches everywhere");
    return;
  };

  if ($query->is_nothing) {
    return $query->builder->nothing;
  };

  if ($query->is_negative) {
    $query->warning(782, 'Exclusivity of query is ignored');
    # TODO:
    #   Better not search at all, because in case the query was classed,
    #   this class information would be lost in the normalization process, so
    #   {1:[!der]} would become [der], which is somehow weird.
    $query->is_negative(0);
  };

  if ($query->is_optional) {
    $query->warning(781, "Optionality of query is ignored");
    $query->is_optional(0);
  };

  $query = $query->_finalize;


  # TODO:
  #   This needs to be in the finalize stage
  #   on the segment level!

  # There is a possible 'any' extension,
  # that may exceed the text
  if ($query->is_extended_right) {
    return $self->builder->in_text($query);
  };

  # Return the planned query
  # TODO: Check for serialization errors
  return $query;
};


sub remove_unused_classes {
  my ($self, $classes) = @_;
  my $used = $self->uses_classes;
  # Pass classes required for highlighting or grouping,
  # and take classes from uses_classes() into account.
  # This is not done recursively, as it first needs to
  # gather all classes and then can remove them.
};


# Remove classes passed as an array references
sub remove_classes {
  my ($self, $keep) = @_;
  unless ($keep) {
    $keep = [];
  };
  $self->{span} = $self->{span}->remove_classes($keep);
  return $self;
};


# Prepare a query for an index
# TODO: Rename to compile()
sub prepare_for {
  my ($self, $index) = @_;

  warn 'DEPRECATED';
  
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


# This will remove classes
# in subqueries
sub plan_without_classes_for {
  shift->plan_for(@_);
};


# Filter a query based on a document query
sub filter_by {
  ...
};

# sub is_any            { $_[0]->{any}            // 0 };
# Matches everything
sub is_any {
  my $self = shift;
  if (defined $_[0]) {
    $self->{any} = shift;
  };
  return $self->{any} // 0;
};

sub is_optional       {
  my $self = shift;
  if (defined $_[0]) {
    $self->{optional} = shift;
  };
  return $self->{optional} // 0;
};

# Null is empty - e.g. in
# Der >alte{0}< Mann
sub is_null           { $_[0]->{null}           // 0 };

# Nothing matches nowhere - e.g. in
# Der [alte & !alte] Mann
# sub is_nothing        { $_[0]->{nothing}        // 0 };
sub is_nothing {
  my $self = shift;
  if (defined $_[0]) {
    $self->{nothing} = shift;
  };
  return $self->{nothing} // 0;
};

sub is_leaf           { 0 };
sub is_extended_right { $_[0]->{extended_right} // 0 };
sub is_extended_left  { $_[0]->{extended_left}  // 0 };
sub is_extended       { $_[0]->is_extended_right || $_[0]->is_extended_left // 0 };
sub freq              {
  warn 'DEPRECATED - only available in queries';
  -1;
};
sub type              { '' };

# Returns a list of classes used by the query,
# e.g. in a focus() context.
sub uses_classes;

sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    $self->{negative} = shift;
    return $self;
  };
  return $self->{negative} // 0;
};


sub toggle_negative {
  my $self = shift;
  $self->is_negative($self->is_negative ? 0 : 1);
  return $self;
};


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


# Iterate over all subqueries and possibly replace them
sub subqueries;

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
      warn 'Operation ' . $op . ' no supported';
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

sub to_neutral {
  $_[0]->to_string;
};


# TODO: This may be optimizable and
# implemented in all query and corpus wrappers
sub to_signature {
  md5_sum $_[0]->to_string;
};

# TODO: Returns a value of complexity of the query,
# that can be used to decide, if a query should be cached.
sub complexity;

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


# Serialization helper
sub boundary {
  my $self = shift;
  my %hash = (
    '@type' => 'koral:boundary'
  );
  $hash{min} = $self->{min} if defined $self->{min};
  $hash{max} = $self->{max} if defined $self->{max};
  return \%hash;
}


1;


__END__

