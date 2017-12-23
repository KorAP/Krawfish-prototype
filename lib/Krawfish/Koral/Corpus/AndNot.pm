package Krawfish::Koral::Corpus::AndNot;
use Role::Tiny::With;
use Krawfish::Corpus::AndNot;
use Krawfish::Log;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;

# Construct AndNot query based on a positive and a negative operand
sub new {
  my $class = shift;
  bless {
    operands => [@_]
  }, $class;
};


# Query type
sub type {
  'AndNot';
};


# May be called
sub _resolve_negative {
  $_[0];
};


sub toggle_negativity {
  ...
};


# Normalize queries
sub normalize {
  my $self = shift;

  # Normalize first operand
  $self->{operands}->[0] = $self->{operands}->[0]->normalize;

  # Normalize and simplify negative operand
  $self->{operands}->[1] = $self->{operands}->[1]->remove_classes->normalize;
  return $self;
};


# Optimize query
sub optimize {
  my ($self, $segment) = @_;
  my ($pos, $neg) = @{$self->operands};

  if (DEBUG) {
    print_log('kq_andnot', 'Plan andnot');
  };

  # Get the positive query
  my $pos_query = $pos->optimize($segment);

  if ($pos_query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  # Get the negative query
  my $neg_query = $neg->optimize($segment);

  if ($neg_query->max_freq == 0) {
    return $pos_query;
  };

  # Build andNot query
  return Krawfish::Corpus::AndNot->new($pos_query, $neg_query);
};



# Check for classes
sub has_classes {
  my $self = shift;

  # Classes in neg are irrelevant
  return $self->{operands}->[0]->has_classes // 0;
};


# Return koral - this is not necessary to be implemented,
# as "AndNot" is an intermediate query
sub to_koral_fragment {
  ...
};


sub from_koral {
  ...
};

# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $op = '&!';

  return '(' . join($op, map {
    $_->type eq 'fieldGroup' ?
      (
        $_->is_anywhere ?
          '[1]' :
          (
            @{$_->operands} > 1 ?
              '(' . $_->to_string . ')'
              :
              $_->to_string($id)
          )
        )
      :
      $_->to_string($id)
    } @{$self->operands}) . ')';
};


1;
