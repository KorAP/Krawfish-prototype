package Krawfish::Koral::Query;
use Role::Tiny;
# use Krawfish::Koral::Query::Builder;
use Krawfish::Log;
use Mojo::Util qw/md5_sum/;
use warnings;
use strict;

with 'Krawfish::Koral::Report';

# TODO:
#   Introduce operation-prefix e.g.
#   ~span() or $span for to_sort_string()!

# TODO:
#   Share a role with Koral::Corpus and Koral::Report::Failure
requires qw/normalize
            optimize
            identify
            type
            operands
            operand
            finalize

            uses_classes

            is_anywhere
            is_optional
            is_null
            is_nowhere
            is_leaf
            is_extended_right
            is_extended_left
            is_negative

            maybe_anchor
            maybe_unsorted

            min_span
            max_span

            from_koral

            to_koral_fragment
            to_string
            to_signature/;
# Base class for span queries

# TODO:
#   - extended_* may be queried
#     automatically without parameter
#   - rename all sorts of single ops to operand
#   - rename all sorts of multiple ops to operands

# TODO:
#   This is now double with Krawfish::Koral!

use constant {
  DEBUG => 0
};


# Constructor
sub new {
  my $class = shift;
  bless {
    anywhere => 0,
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


# Refer to common subqueries
sub refer {
  $_[0];
};

# Translate to ids
# TODO:
#   If "nowhere" returns, optimize away
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
  if ($query->is_anywhere || $query->is_null) {
    $self->error(780, "This query matches everywhere");
    return;
  };


  # The query matches nowhere
  if ($query->is_nowhere) {
    return $query->builder->nowhere;
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

  # There is a possible 'anywhere' extension,
  # that may exceed the text boundary
  if ($query->is_extended_right) {
    return $self->builder->in_text($query);
  };

  # Return the planned query
  # TODO:
  #   Check for serialization errors
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

sub uses_classes {
  warn 'Not yet implemented';
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
      $self->move_info_from($op);
      push @new_ops, $op;
    };
    $self->{operands} = \@new_ops;
  };
  $self->{operands};
};


# Get and set first and only operand
sub operand {
  my $self = shift;

  if (@_ == 1) {
    $self->{operands} = [shift];
  };
  return $self->{operands}->[0];
};


# Matches everything
sub is_anywhere {
  my $self = shift;
  if (defined $_[0]) {
    $self->{anywhere} = shift;
  };
  return $self->{anywhere} // 0;
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
  my $self = shift;
  if (defined $_[0]) {
    $self->{null} = shift;
  };
  return $self->{null} // 0;
};


# Nothing matches nowhere - e.g. in
# Der [alte & !alte] Mann
sub is_nowhere {
  my $self = shift;
  if (defined $_[0]) {
    $self->{nowhere} = shift;
  };
  return $self->{nowhere} // 0;
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
  return if $self->is_anywhere;
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


#############################
# Query Application methods #
#############################

# Serialize
#sub to_koral_query {
#  my $self = shift;
#  my $koral = $self->to_koral_fragment;
#  $koral->{'@context'} = CONTEXT;
#  $koral;
#};


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
sub complexity {
  warn 'override';
};


# Create KoralQuery builder
sub builder {
  return Krawfish::Koral::Query::Builder->new;
};


# sub replace_references {
#   my ($self, $refs) = @_;
#   my $sig = $self->signature;
#
#   # Subquery is identical to given query
#   if ($refs->{$sig}) {
#     ...
#   }
#   else {
#     $refs->{$sig} = $self->operand;
#   };
# };


sub to_sort_string {
  $_[0]->to_string;
};

1;
