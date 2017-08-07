package Krawfish::Koral::Query;
use parent 'Krawfish::Info';
# TODO: Use the same parent as Koral::Corpus
use Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Query::Importer;
use Krawfish::Log;
use Mojo::Util qw/md5_sum/;
use warnings;
use strict;

# TODO:
#   - rename 'nothing' to 'nowhere'
#   - rename 'any' to 'anywhere'
#   - extended_* may be queried
#     automatically without parameter
#   - rename all sorts of single ops to operand
#   - rename all sorts of multiple ops to operands

# TODO:
#   This is now double with Krawfish::Koral!
use constant {
  CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld',
  DEBUG => 0
};

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


sub type;


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


# Expand regular expressions
sub inflate {
  my ($self, $dict) = @_;

  warn 'Inflate is deprecated - use ->identify()';

  my $ops = $self->operands;
  return $self unless $ops;
  for (my $i = 0; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->inflate($dict);
  };
  return $self;
};


# TODO:
#   If "nothing" returns, optimize away
#   before ->optimize().
sub identify {
  my ($self, $dict) = @_;

  my $ops = $self->operands;
  return $self unless $ops;
  for (my $i = 0; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->identify($dict);
  };
  return $self;
};




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


# Treat the operand like a root operand
sub finalize {
  my $self = shift;

  if (DEBUG) {
    print_log('kq_query', 'Finalize query ' . $self->to_string);
  };

  my $query = $self;

  # The query matches everywhere
  if ($query->is_any || $query->is_null) {
    $self->error(780, "This query matches everywhere");
    return;
  };


  # The query matches nowhere
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

  # Ignore optionality
  if ($query->is_optional) {
    $query->warning(781, "Optionality of query is ignored");
    $query->is_optional(0);
  };

  # Use a finalize method
  $query = $query->_finalize;

  # TODO:
  #   This needs to be in the finalize stage
  #   on the segment level!

  # There is a possible 'any' extension,
  # that may exceed the text boundary
  if ($query->is_extended_right) {
    return $self->builder->in_text($query);
  };

  # Return the planned query
  # TODO:
  #   Check for serialization errors
  return $query;
};


# Returns a list of classes used by the query,
# e.g. in a focus() context.
sub uses_classes;


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
  my $ops = $self->operands;

  return $self unless $ops;

  for (my $i = 0; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->remove_classes($keep);
  };
  return $self;
};


# Get and set operands
sub operands {
  my $self = shift;
  if (@_) {
    my $ops = shift;
    my @new_ops = ();
    foreach my $op (@$ops) {
      $self->remove_info_from($op);
      push @new_ops, $op;
    };
    $self->{operands} = \@new_ops;
  };
  $self->{operands};
};


# Get and set first and only operand
sub operand {
  if (@_ == 2) {
    $_[0]->{operands} = [$_[1]];
  };
  $_[0]->{operands}->[0];
};


#sub replace_references {
#  my ($self, $refs) = @_;
#  my $sig = $self->signature;
#
#  # Subquery is identical to given query
#  if ($refs->{$sig}) {
#    ...
#  }
#  else {
#    $refs->{$sig} = $self->operand;
#  };
#};


# Matches everything
sub is_any {
  my $self = shift;
  if (defined $_[0]) {
    $self->{any} = shift;
  };
  return $self->{any} // 0;
};



# Is optional
sub is_optional {
  my $self = shift;
  if (defined $_[0]) {
    $self->{optional} = shift;
  };
  return $self->{optional} // 0;
};


# Null is empty - e.g. in
# Der >alte{0}< Mann
sub is_null {
  $_[0]->{null} // 0
};


# Nothing matches nowhere - e.g. in
# Der [alte & !alte] Mann
sub is_nothing {
  my $self = shift;
  if (defined $_[0]) {
    $self->{nothing} = shift;
  };
  return $self->{nothing} // 0;
};


# Check if the query is a leaf node in the tree
sub is_leaf {
  0;
};


# Check if the result of the query is extended to the right
sub is_extended_right {
  $_[0]->{extended_right} // 0
};


# Check if the result of the query is extended to the left
sub is_extended_left {
  $_[0]->{extended_left} // 0
};


# Check if the result of the query is extended
sub is_extended {
  $_[0]->is_extended_right || $_[0]->is_extended_left // 0
};


# Is negative
sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    $self->{negative} = shift;
    return $self;
  };
  return $self->{negative} // 0;
};


# Toggle negativity
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
# TODO:
#   Rename to classes_maybe_unsorted
sub maybe_unsorted {
  $_[0]->{maybe_unsorted} // 0
};


# Get the minimum tokens the query spans
sub min_span {
  ...
};


# Get the maximum tokens the query spans
# -1 means arbitrary
sub max_span {
  ...
};


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

sub to_koral_query {
  my $self = shift;
  my $koral = $self->to_koral_fragment;
  $koral->{'@context'} = CONTEXT;
  $koral;
};

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
};


1;


__END__

