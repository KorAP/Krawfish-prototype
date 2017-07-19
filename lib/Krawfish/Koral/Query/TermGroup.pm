package Krawfish::Koral::Query::TermGroup;
use parent ('Krawfish::Koral::Util::BooleanTree','Krawfish::Koral::Query');
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

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $operation = shift;

  # Make all operands, terms
  my @operands = map {
    blessed $_ ? $_ : Krawfish::Koral::Query::Term->new($_)
  } @_;

  bless {
    operation => $operation,
    operands => [@operands],
    filter => undef
  }
};

sub type {
  'termGroup'
};


sub build_or {
  shift;
  __PACKAGE__->new('or',@_);
};


sub build_and {
  shift;
  __PACKAGE__->new('and', @_);
};


# Build AndNot group
sub build_and_not {
  my ($self, $pos, $neg) = @_;
  my $query = $self->builder->exclusion(['matches'], $pos, $neg);
  print_log('kq_tgroup', 'Create andNot: ' . $query->to_string) if DEBUG;
  $query;
};


sub build_any {
  shift;
  my $any = Krawfish::Koral::Query::TermGroup->new;
  $any->is_any(1);
  return $any;
};


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

    # Get operands in alphabetical order
  my $ops = $self->operands_in_order;

  # Check the frequency of all operands
  # Start with a query != null
  my $i = 0;
  my $first = $ops->[$i];

  print_log('kq_tgroup', 'Initial query is ' . $self->to_string) if DEBUG;

  my $query = $first->optimize($index);
  $i++;

  # Check unless
  while ($query->max_freq == 0 && $i < @$ops) {
    $first = $ops->[$i++];
    $query = $first->optimize($index);
    $i++;
  };

  if ($self->operation eq 'or') {
    print_log('kq_tgroup', 'Prepare or-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      # TODO: Check for negation!
      my $next = $ops->[$i]->optimize($index);

      if ($next->max_freq != 0) {

        # TODO: Distinguish here between classes and non-classes!
        $query = Krawfish::Query::Or->new(
          $query,
          $next
        );
      };
    };
  }

  elsif ($self->operation eq 'and') {
    print_log('kq_tgroup', 'Prepare and-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      my $next = $ops->[$i]->optimize($index);

      if ($next->max_freq != 0) {

        # TODO: Distinguish here between classes and non-classes!
        $query = Krawfish::Query::Constraints->new(
          [Krawfish::Query::Constraint::Position->new(MATCHES)],
          $query,
          $next
        );
      }

      # One operand is not existing
      else {
        return Krawfish::Query::Nothing->new;
      };
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


# Filter by corpus
sub filter_by {
  my $self = shift;
  $self->{filter} = shift;
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

1;
