package Krawfish::Koral::Query::Or;
use parent ('Krawfish::Koral::Util::BooleanTree','Krawfish::Koral::Query');
use Krawfish::Log;
use Krawfish::Query::Or;
use strict;
use warnings;

# Or-Construct on spans

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    operands => [@_]
  }
};

sub type {
  'or'
};

sub operation {
  'or'
};

sub operands {
  my $self = shift;
  if (@_) {
    print_log('kq_or', 'Set operands') if DEBUG;
    $self->{operands} = shift;
  };
  $self->{operands};
};


# Optimize Or-operand sequence
sub optimize {
  my ($self, $index) = @_;

  # Get operands in alphabetical order
  my $ops = $self->operands_in_order;

  my $i = 0;
  my $first = $ops->[$i];

  print_log('kq_or', 'Initial query is ' . $self->to_string) if DEBUG;

  my $query = $first->optimize($index);
  $i++;

  # Check to get a valid first query
  while ($query->freq == 0 && $i < @$ops) {
    $first = $ops->[$i++];
    $query = $first->optimize($index);
    $i++;
  };

  for (; $i < @$ops; $i++) {
    # Get query operation for next operand
    # TODO: Check for negation!
    my $next = $ops->[$i]->optimize($index);

    if ($next->freq != 0) {
      $query = Krawfish::Query::Or->new(
        $query,
        $next
      );
    };
  };

  if ($query->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return $query;
};


# Create operands in order
sub operands_in_order {
  my $self = shift;
  my $ops = $self->{operands};
  return [ sort { $a->to_string cmp $b->to_string } @$ops ];
};


# Stringification
sub to_string {
  my $self = shift;
  return join '|', map { '(' . $_->to_string . ')'} @{$self->operands_in_order};
};

# Remove classes passed as an array references
sub remove_classes {
  my ($self, $keep) = @_;
  unless ($keep) {
    $keep = [];
  };
  my $ops = $self->operands;
  for (my $i = 0; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->remove_classes($keep);
  };
  $self->operands($ops);
  return $self;
};

1;
