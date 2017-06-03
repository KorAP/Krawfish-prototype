package Krawfish::Koral::Corpus::AndNot;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::Without;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    pos => shift,
    neg => shift
  }, $class;
};


sub type {
  'AndNot';
};


# May be called
sub _resolve_negative {
  $_[0];
};


sub toggle_negativity;


sub optimize {
  my ($self, $index) = @_;
  my $pos = $self->{pos};
  my $neg = $self->{neg};

  if (DEBUG) {
    print_log('kq_andnot', 'Plan andnot') if DEBUG;
  };

  # Get the positive query
  my $pos_query = $pos->optimize($index);

  if ($pos_query->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Get the negative query
  my $neg_query = $neg->optimize($index);

  if ($neg_query->freq == 0) {
    return $pos_query;
  };

  # Build Without query
  return Krawfish::Corpus::Without->new($pos_query, $neg_query);
};



# Check for classes
sub has_classes {
  my $self = shift;

  return ($self->{pos}->has_classes ||
            $self->{neg}->has_classes) // 0;
};


# Return koral - this is not necessary to be implemented,
# as "AndNot" is an intermediate query
sub to_koral_fragment;


# Stringification
sub to_string {
  my $self = shift;

  my $op = '&!';

  return join($op, map {
    $_->type eq 'fieldGroup' ?
      (
        $_->is_any ?
          '[1]' :
          (
            @{$_->operands} > 1 ?
              '(' . $_->to_string . ')'
              :
              $_->to_string
          )
        )
      :
      $_->to_string
    } ($self->{pos}, $self->{neg}));
};







sub plan_for {

  warn 'DEPRECATED';
  my ($self, $index) = @_;
  my $pos = $self->{pos};
  my $neg = $self->{neg};

  if (DEBUG) {
    print_log('kq_andnot', 'Plan andnot') if DEBUG;
  };

  # Get the positive query
  my $pos_query = $pos->plan_for($index);

  if ($pos_query->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Get the negative query
  my $neg_query = $neg->plan_for($index);

  if ($neg_query->freq == 0) {
    return $pos_query;
  };

  return Krawfish::Corpus::Without->new($pos_query, $neg_query);
};




1;
