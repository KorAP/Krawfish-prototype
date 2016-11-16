package Krawfish::Posting;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use Krawfish::Posting::Payload;
use strict;
use warnings;

# Constructor
sub new {
  my $class = shift;
  bless { @_ }, $class;
};


# Current document
sub doc_id {
  return $_[0]->{doc_id};
};


# Start of span
sub start {
  return $_[0]->{start};
};


# End of span
sub end {
  return $_[0]->{end};
};


# Payloads
sub payload {
  return $_[0]->{payload} //= Krawfish::Posting::Payload->new;
};


# Stringify
sub to_string {
  my $self = shift;
  my $str = '[' .
    $self->doc_id . ':' .
    $self->start . '-' .
    $self->end;

  if ($self->payload->length) {
    $str .= '$' . $self->payload->to_string;
  };

  return $str . ']';
};

sub compare {
  my ($self, $comp) = @_;
  return unless $comp;
  return $self->to_string eq $comp->to_string;
};

1;
