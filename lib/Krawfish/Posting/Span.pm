package Krawfish::Posting::Span;
use parent 'Krawfish::Posting';
use Krawfish::Posting::Payload;
use strict;
use warnings;

# Posting representing a single token

# Constructor
sub new {
  my $class = shift;
  bless { @_ }, $class;
}

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
  return $_[0]->{end} // $_[0]->{start} + 1
};


# Payloads
sub payload {
  return $_[0]->{payload} //= Krawfish::Posting::Payload->new;
};


# Compare posting order
sub compare {
  my ($self, $post) = @_;
  return 1 unless $post;

  # First has a small
  if ($self->doc_id > $post->doc_id) {
    return -1;
  }
  elsif ($self->doc_id == $post->doc_id) {
    if ($self->start > $post->start) {
      return -1;
    }
    elsif ($self->start == $post->start) {
      if ($self->end > $post->end) {
        return -1;
      };
    };
  };
  return 1;
};


# Return all classes in the payload
sub get_classes {
  my ($self, $nrs) = @_;

  # Check payload for relevant class and return start, end
  # If no nrs are given, return all classes
  my @classes = ();

  # Better check with smartmatch
  if (!$nrs || $nrs->[0] == 0)  {
    push @classes, [0, $self->start, $self->end]
  };

  # No more payloads
  return @classes unless $self->payload;

  # Check payloads for classes
  foreach my $pl ($self->payload->to_array) {

    # Payload is class
    if ($pl->[0] == PTI_CLASS) {

      # Return all classes
      unless ($nrs) {
        push @classes, [$pl->[1], $pl->[2], $pl->[3]];
      }

      # Check if wanted
      else {
        # TODO: Optimize to not iterate over
        # numbers multiple times
        foreach (@$nrs) {

          # TODO:
          #   Be aware:
          #   Classes can be set multiple times!
          #   And classes can be with gaps!
          if ($pl->[1] == $_) {
            push @classes, [$pl->[1], $pl->[2], $pl->[3]];
          };
        };
      };
    };
  };

  # Get class information
  return @classes;
};


# Return classes sorted by start position
sub get_classes_sorted {
  my ($self, $nrs) = @_;
  # The same as get_classes, but ordered by start position

  return sort { $a->[1] <=> $b->[1] } $self->get_classes($nrs);
};


# Clone the posting with all information
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    doc_id => $self->doc_id,
    start => $self->start,
    end => $self->end,
    payload => defined $self->{payload} ? $self->payload->clone : undef,
    flags => $self->{flags}
  );
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[' .
    $self->doc_id . ':' .
    $self->start . '-' .
    $self->end;

  if ($self->corpus_flags & 0b0111_1111_1111_1111) {
    $str .= '!' . join(',', $self->corpus_classes);
  };

  if ($self->payload->length) {
    $str .= '$' . $self->payload->to_string;
  };

  return $str . ']';
};



1;
