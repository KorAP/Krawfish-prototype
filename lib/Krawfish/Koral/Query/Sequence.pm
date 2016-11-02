package Krawfish::Koral::Query::Sequence;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{array} = [@_];
  return $self;
};

sub append {
  push @{$_[0]->{array}}, shift;
};

sub prepend {
  unshift @{$_[0]->{array}}, shift;
};

sub size {
  scalar @{$_[0]->{array}};
};

# TODO: Order by frequency, so the most common occurrence is at the outside
sub plan_for {
  ...
#  my $self = shift;
#  my @elements = @{$self->{array}};
#  foreach (@elements) {
#  }
};

sub is_any {
  ...
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

