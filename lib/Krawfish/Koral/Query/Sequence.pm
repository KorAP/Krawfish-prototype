package Krawfish::Koral::Query::Sequence;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{array} = [@_];
  $self->{planned} = 0;
  $self->{info} = undef;
  return $self;
};


sub append {
  $_[0]->{planned} = 0;
  push @{$_[0]->{array}}, shift;
};


sub prepend {
  $_[0]->{planned} = 0;
  unshift @{$_[0]->{array}}, shift;
};


sub size {
  scalar @{$_[0]->{array}};
};


# TODO: Order by frequency, so the most common occurrence is at the outside
sub plan_for {
  my $self = shift;

  # Only one element available
  if ($self->size == 1) {

    # Return this element
    return $self->plan_for(
      $self->{array}->[0]
    );
  };

  $self->{planned} = 1;
};

sub _pre_plan {
  my $self = shift;
  # First pass - mark anchors
  my @anchors = ();
  for (my $i = 0; $i < $self->size; $i++) {
    if ($self->{array}->[$i]->maybe_anchor) {
      push @anchors, $i;
    };
  };
};

sub is_any {
  my $self = shift;
  return $self->{any} if $self->{planned} && $self->{any};
  ...
};


sub is_null {
  
};



sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:sequence',
    'operands' => [
      map { $_->to_koral_fragment } @{$self->{array}}
    ]
  };
};

sub to_string {
  return join '', map { $_->to_string } @{$_[0]->{array}};
};


1;


__END__

Rewrite rules:
- [Der][alte][Mann]? ->
  [Der]optExt([alte],[Mann])

