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
#   -> identify()
#   -> finalize()
#   -> memoize(cache)
#   -> optimize(index)


# TODO: Flatten or-groups in a first pass!
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
    operands => [@operands]
  }
};


# Query type
sub type {
  'termGroup'
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


# Create a token based and-query
sub bool_and_query {
  my $self = shift;
  Krawfish::Query::Constraints->new(
    [Krawfish::Query::Constraint::Position->new(MATCHES)],
    $_[0],
    $_[1]
  );
};


# Create a token based or-query
sub bool_or_query {
  my $self = shift;
  Krawfish::Query::Or->new(
    $_[0],
    $_[1]
  );
};


# The result can't be unsorted,
# as no term can be unsorted
sub maybe_unsorted {
  0
};

#sub is_anywhere {
#  my $self = shift;
  # return 0 if $self->is_nowhere;
  # return 1 if @{$self->operands} == 0;
#  return $self->{anywhere};
#};


# A termGroup always spans exactly one token
sub min_span {
  return 0 if $_[0]->is_null;
  1;
};


# A termGroup always spans exactly one token
sub max_span {
  return 0 if $_[0]->is_null;
  1;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $str = '';

  if ($self->is_negative) {

    if ($self->is_nowhere) {
      return '1';
    }
    elsif ($self->is_anywhere) {
      return '0';
    }
    else {
      $str .= '!';
    };
  }

  # matches
  elsif ($self->is_nowhere) {
    return '0';
  }

  # Matches everywhere
  elsif ($self->is_anywhere) {
    return '1';
  };


  my $op = $self->operation eq 'and' ? '&' : '|';
  my $inner = join $op, map {
    $_->type eq 'termGroup' ? '(' . $_->to_string($id) . ')' : $_->to_string($id)
  } @{$self->operands_in_order};
  if ($str) {
    return "$str($inner)";
  };
  return $inner;
};


# Stringify without negation
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
