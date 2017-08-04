package Krawfish::Koral::Meta::Node::Enrich::Fields;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

# TODO:
#   Inflate on the enrichments!

sub new {
  my $class = shift;
  bless {
    query => shift,
    fields => shift
  }, $class;
};


sub to_string {
  my $self = shift;
  return 'fields(' . join(',', map { $_->to_string } @{$self->{fields}}) .
    ':' . $self->{query}->to_string . ')';
};


sub identify {
  my ($self, $dict) = @_;

  my @identifier;
  foreach (@{$self->{fields}}) {

    # Field may not exist in dictionary
    my $field = $_->identify($dict);
    if ($field) {
      push @identifier, $field;
    };
  };

  $self->{query} = $self->{query}->identify($dict);

  # Do not return any fields
  return $self->{query} if @identifier == 0;

  $self->{fields} = \@identifier;

  return $self;
};


1;
