package Krawfish::Koral::Result;
use parent 'Krawfish::Info';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    collection => {},
    matches => []
  }, $class;
};


# Add matches to the result
sub add_match {
  my ($self, $match) = @_;
  push @{$self->{matches}}, $match;
};


# Add collected information to the head
sub add_collection {
  my ($self, $collection) = @_;
  $self->{collection} = $collection;
};


sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:result',
    'collection' => $self->{collection}->to_koral_fragment,
    'matches' => [
      map { $_->to_koral_fragment } @{$self->{matches}}
    ]
  };
};


1;

__END__
