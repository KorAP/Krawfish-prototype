package Krawfish::Posting;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use Krawfish::Posting::Payload;
use strict;
use warnings;

# TODO:
#   Ensure that flags are serialized!

# Constructor
sub new {
  my $class = shift;
  bless { @_ }, $class;
};


# Current document
sub doc_id {
  return $_[0]->{doc_id};
};


# Flags for corpus classes
sub flags {
  # Class 0 is set per default
  return $_[0]->{flags} //= 0b1000_0000_0000_0000;
};


# Return a new flags, that represents
# the intersection of the flags with given flags
sub flags_intersect {
  my ($self, $flags) = @_;

  # Returns a new flag
  return $self->flags & $flags;
};


# Returns a list of matching query corpus classes
sub flags_list {

  # TODO:
  #   The implementation is quite naive and
  #   should be optimized
  my ($self, $query_flags) = @_;
  my $intersect = $query_flags ? $self->flags_intersect($query_flags) : $self->flags;
  my @list = ();

  # That's quite a naive approach ...
  # Maybe use while ($intersect etc.)
  foreach (0..15) {
    if ($intersect & (0b1000_0000_0000_0000 >> $_)) {
      push @list, $_;
    };
  };

  # Return list of valid classes
  return @list;
};


# Check if two postings are identical
# WARNING:
#   This should compare payloads separately,
#   because classes may be in different order,
#   though resulting in identical postings
sub same_as {
  my ($self, $comp) = @_;
  return unless $comp;
  return $self->to_string eq $comp->to_string;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[' . $self->{doc_id};

  if ($self->flags & 0b0111_1111_1111_1111) {
    $str .= '!' . ($self->flags + 0);
  };

  $str . ']';
};



1;
