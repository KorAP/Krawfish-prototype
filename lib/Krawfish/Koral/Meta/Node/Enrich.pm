package Krawfish::Koral::Meta::Node::Enrich;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;

  warn 'DEPRECATED';


  my $self = bless {
    query => shift,
    enrichments => shift
  }, $class;
};



# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  warn 'DEPRECATED';

  
  my @identifier;
  foreach (@{$self->{enrichments}}) {
    my $enrich = $_->identify($dict);

    if ($enrich) {
      push @identifier, $enrich;
    };
  };

  $self->{query} = $self->{query}->identify($dict);

  return $self->{query} if @identifier == 0;

  $self->{enrichments} = \@identifier;

  return $self;

};


sub to_string {
  my $self = shift;

  warn 'DEPRECATED';

  return 'enrich(' .
    join(',', map { $_->to_string } @{$self->{enrichments}}) .
    ':' . $self->{query}->to_string . ')';
};



1;
