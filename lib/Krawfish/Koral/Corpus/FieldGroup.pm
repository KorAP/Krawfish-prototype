package Krawfish::Koral::Corpus::FieldGroup;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Log;
use Krawfish::Corpus::Or;
use Krawfish::Corpus::And;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    operation => shift,
    operands => [@_]
  }, $class;
};

sub type {
  'fieldGroup';
};

sub operation {
  $_[0]->{operation};
};

sub operands {
  $_[0]->{operands}
};

sub plan_for {
  my ($self, $index) = @_;

  my $ops = $self->operands;

  # TODO: Deal with negatives!

  my $i = 0;

  # Check the frequency of all operands
  # Start with a query != null
  my $query = $ops->[$i++]->plan_for($index);

  # Check unless
  while ($query->freq == 0 && $i < @$ops) {
    $query = $ops->[$i++]->plan_for($index);
  };

  # serialize for 'or' operation
  if ($self->operation eq 'or') {

    print_log('kq_fgroup', 'Prepare or-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {
      my $option = $ops->[$i]->plan_for($index);
      if ($option->freq != 0) {
        $query = Krawfish::Corpus::Or->new(
          $query,
          $option
        )
      };
    };
  }

  elsif ($self->operation eq 'and') {

    print_log('kq_fgroup', 'Prepare and-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {
      my $option = $ops->[$i]->plan_for($index);
      if ($option->freq != 0) {
        $query = Krawfish::Corpus::And->new(
          $query,
          $option
        )
      };
    };
  };

  if ($query->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return $query;
};


sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:fieldGroup',
    operation => 'operation:' . $self->operation,
    operands => [ map { $_->to_koral_fragment } @{$self->{operands}} ]
  };
};

sub to_string {
  my $self = shift;
  my $op = $self->operation eq 'and' ? '&' : '|';

  join $op, map {
    $_->type eq 'fieldGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } @{$self->operands};
};

1;
