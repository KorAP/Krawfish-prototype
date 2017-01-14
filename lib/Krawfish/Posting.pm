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


sub get_classes {
  my ($self, $nrs) = @_;
  # Check payload for relevant class and return start, end
  # If no nrs are given, return all classes
  my @classes = ();
  if ($nrs->[0] == 0)  {
    push @classes, [0, $self->start, $self->end]
  };
  return @classes;
};


sub get_classes_sorted {
  my ($self, $nrs) = @_;
  # The same as get_classes, but ordered by start position
  return $self->get_classes($nrs);
}

# This will be overwritten for at least cached buffers
# necessary for sorting
sub offset {
  undef;
};


sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    doc_id => $self->doc_id,
    start => $self->start,
    end => $self->end,
    payload => $self->payload->clone
  );
}

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
