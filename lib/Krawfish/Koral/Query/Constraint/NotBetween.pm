package Krawfish::Koral::Query::Constraint::NotBetween;
use Krawfish::Query::Constraint::NotBetween;
use strict;
use warnings;

# Check that a query between two operands is does nmot occur.
# In case this operand never occurs, it will at least set a relevant length.

sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};


sub type {
  'constr_not_beteween';
};


sub to_string {
  my $self = shift;
  return 'notBetween=' . $self->{query}->to_string;
};


sub normalize {
  my $self = shift;

  my $query;
  unless ($query = $self->{query}->normalize) {
    # TODO something like this: $self->copy_info_from($self->span);
    return;
  };

  # Remove all classes here, because they can't occur
  $query = $query->remove_classes;

  $self->{query} = $query;
  $self;
};


# Optimize constraint
sub optimize {
  my ($self, $index) = @_;

  # Optimize query
  my $query = $self->{query}->optimize($index);

  # Span has no match
  return if $query->max_freq == 0;

  # Return valid constraint
  return Krawfish::Query::Constraint::NotBetween->new($query);
};


sub inflate {
  my ($self, $dict) = @_;
  $self->{query} = $self->{query}->inflate($dict);
  $self;
};

1;
