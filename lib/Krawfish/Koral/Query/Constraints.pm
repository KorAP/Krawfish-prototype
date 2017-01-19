package Krawfish::Koral::Query::Constraints;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Constraints;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    constraints => shift,
    first => shift,
    second => shift
  }
};

sub to_koral_fragment {
  ...
};

sub type { 'constraints' };

sub plan_for {
  my ($self, $index) = @_;

  my ($first, $second);
  unless ($first = $self->{first}->plan_for($index)) {
    $self->copy_info_from($self->{first});
    return;
  };

  unless ($second = $self->{second}->plan_for($index)) {
    $self->copy_info_from($self->{second});
    return;
  };

  my @constraints = ();
  foreach (@{$self->{constraints}}) {
    push @constraints, $_->plan_for($index)
  };

  return Krawfish::Query::Constraints->new(
    \@constraints,
    $first,
    $second
  );
};


sub filter_by {
  my $self = shift;
  my $corpus_query = shift;
  $self->{first}->filter_by($corpus_query);
  $self->{second}->filter_by($corpus_query);

  # TODO:
  #   filter constraints
};


# TODO: Made helpers constrained knowing

sub maybe_unsorded {
  ...
};


sub to_string {
  my $self = shift;
  my $str = 'constr(';
  $str .= join(',', map { $_->to_string } @{$self->{constraints}});
  $str .= ':';
  $str .= $self->{first}->to_string . ',' . $self->{second}->to_string;
  return $str . ')';
};


1;
