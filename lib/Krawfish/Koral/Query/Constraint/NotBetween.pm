package Krawfish::Koral::Query::Constraint::NotBetween;
use Krawfish::Query::Constraint::NotBetween;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'notBetween=' . $self->{query}->to_string;
};

sub plan_for {
  my ($self, $index) = @_;
  my $query;

  unless ($query = $self->{query}->plan_without_classes_for($index)) {
    # TODO something like this: $self->copy_info_from($self->span);
    return;
  };

  # Span has no match
  if ($query->freq == 0) {
    return;
  };

  return Krawfish::Query::Constraint::NotBetween->new($query);
};

1;
