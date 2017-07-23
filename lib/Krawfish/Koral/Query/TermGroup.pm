package Krawfish::Koral::Query::TermGroup;
use parent ('Krawfish::Koral::Util::Boolean','Krawfish::Koral::Query');
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Or;
use Krawfish::Query::Constraints;
use Krawfish::Query::Constraint::Position;
use Krawfish::Log;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

# TODO:
#   Preparation should be:
#   -> normalize()
#   -> inflate()
#   -> finalize()
#   -> memoize(cache)
#   -> optimize(index)

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $operation = shift;

  # Make all operands, terms
  my @operands = map {
    blessed $_ ? $_ : Krawfish::Koral::Query::Term->new($_)
  } @_;

  bless {
    operation => $operation,
    operands => [@operands]
  }
};


# Query type
sub type {
  'termGroup'
};


# Build helper for or-relations
sub build_or {
  shift;
  __PACKAGE__->new('or',@_);
};


# Build helper for and-relations
sub build_and {
  shift;
  __PACKAGE__->new('and', @_);
};


# Build helper for andNot-relations
sub build_and_not {
  my ($self, $pos, $neg) = @_;
  my $query = $self->builder->exclusion(['matches'], $pos, $neg);
  print_log('kq_tgroup', 'Create andNot: ' . $query->to_string) if DEBUG;
  $query;
};


# Build helper for any match
sub build_any {
  shift;
  my $any = Krawfish::Koral::Query::TermGroup->new;
  $any->is_any(1);
  return $any;
};


# Get or set the group operation
sub operation {
  my $self = shift;
  if (@_) {
    $self->{operation} = shift;
    return $self;
  };
  $self->{operation};
};


# There are no classes allowed in term groups
sub remove_classes {
  $_[0];
};


# Create operands in order
sub operands_in_order {
  my $self = shift;
  my $ops = $self->{operands};
  return [ sort { $a->to_string cmp $b->to_string } @$ops ];
};




# TODO: Flatten or groups in a first pass!
# TODO: In case, the group is 'and' and there is at
#       least one positive element, do for negative elements:
#       [tt/l=Baum & tt/p=NN & cnx/p!=NN]
#       excl(match:pos(match, 'tt/l=Baum', 'tt/p=NN'),'cnx/p=NN')
#       and
#       [tt/l=Baum & tt/p=NN & cnx/p!=NN & cnx/p!=ADJA]
#       excl(match:pos(match, 'tt/l=Baum', 'tt/p=NN'), or('cnx/p=NN', 'cnx/p=ADJA'))
# TODO: der [tt/l=Baum | tt/p=NN | cnx/p!=NN]
#       or(
#         seq(
#           'der',
#            or('tt/l=Baum', 'tt/p=NN')
#         ).
#         ext(
#           'right',
#           excl(
#             'precedes',
#             'der'
#             'cnx/p=NN'
#           ),
#           1
#         )
#       )


# TODO:
#   IMPORTANT:
#     for example in an annotation like
#   Mittwoch
#   -------------
#   case:dat
#   gender:masc
#   number:sg
#
#   a query like
#   [case:dat | gender:masc | number:sg]
#   Returns three results.
#   It would be better to wrap or-groups after normalization
#   in unique queries, as long as they don't have classes.
#   so - maybe it would be best to NOT support classes in tokens
#   so - if classes in tokens are needed, they need to be reformulated
#   as token-groups, e.g.
#   {1:[marmot/m=case:dat]}|{2:[marmot/m=gender:masc]}|{3:[marmot/m=number:sg]}
#

# This is rather identical to FieldGroup
sub optimize {
  my ($self, $index) = @_;

  # Get operands
  my $ops = $self->operands;

  # Check the frequency of all operands

  my @freq;
  my $query;

  # Filter out all terms that do not occur
  for (my $i = 0; $i < @$ops; $i++) {

    # Get query operation for next operand
    my $next = $ops->[$i]->optimize($index);

    # Get maximum frequency
    my $freq = $next->max_freq;

    # Push to frequency list
    push @freq, [$next, $freq];
  };

  # Sort operands based on ascending frequency
  @freq = sort {
    ($a->[1] < $b->[1]) ? -1 : (($a->[1] > $b->[1]) ? 1 : ($a->[0]->to_string cmp $b->[0]->to_string))
  } @freq;

  if ($self->operation eq 'or') {
    print_log('kq_tgroup', 'Prepare or-group') if DEBUG;

    # Ignore non-existing terms
    while (@freq && $freq[0]->[1] == 0) {
      shift @freq;
    };

    # No valid operands exist
    if (@freq == 0) {
      return Krawfish::Query::Nothing->new;
    };

    # Get the first operand
    $query = shift(@freq)->[0];

    # For all further queries, create a query tree
    while (@freq) {
      my $next = shift(@freq)->[0];

      # TODO: Distinguish here between classes and non-classes!
      $query = Krawfish::Query::Or->new(
        $query,
        $next
      );
    };
  }

  elsif ($self->operation eq 'and') {
    print_log('kq_tgroup', 'Prepare and-group') if DEBUG;

    # If the least frequent operand does not exist,
    # the whole group can't exist
    if ($freq[0]->[1] == 0) {

      # One operand is not existing
      return Krawfish::Query::Nothing->new;
    };

    # Get the first operand
    $query = shift(@freq)->[0];

    # Make the least frequent terms come first in constraint
    while (@freq) {
      my $next = shift(@freq)->[0];

      # Create constraint with the least frequent as second (buffered) operand
      $query = Krawfish::Query::Constraints->new(
        [Krawfish::Query::Constraint::Position->new(MATCHES)],
        $next,
        $query
      );
    };
  }

  else {
    warn 'Should never happen!';
  };

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return $query;
};


sub maybe_unsorted { 0 };

#sub is_any {
#  my $self = shift;
  # return 0 if $self->is_nothing;
  # return 1 if @{$self->operands} == 0;
#  return $self->{any};
#};

sub to_string {
  my $self = shift;

  my $str = '';

  if ($self->is_negative) {

    if ($self->is_nothing) {
      return '1';
    }
    elsif ($self->is_any) {
      return '0';
    }
    else {
      $str .= '!';
    };
  }

  # matches
  elsif ($self->is_nothing) {
    return '0';
  }

  # Matches everywhere
  elsif ($self->is_any) {
    return '1';
  };


  my $op = $self->operation eq 'and' ? '&' : '|';
  my $inner = join $op, map {
    $_->type eq 'termGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } @{$self->operands_in_order};
  if ($str) {
    return "$str($inner)";
  };
  return $inner;
};


sub to_neutral {
  my $self = shift;
  my $string = $self->to_string;
  if ($self->is_negative) {
    $string =~ s/^!\((.+?)\)$/$1/o;
  };
  $string;
};


# Return Koral fragment
sub to_koral_fragment {
  my $self = shift;

  my $group = {
    '@type' => 'koral:group',
    'operation' => 'operation:termGroup',
    'relation' => 'relation:' . $self->operation
  };

  my $ops = ($group->{operands} = []);

  foreach my $op (@{$self->operands}) {
    push @$ops, $op->to_koral_fragment;
  };

  $group;
};



1;
