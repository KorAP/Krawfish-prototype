package Krawfish::Koral::Corpus::FieldID;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::FieldID;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   - Check for valid parameters
#   - Only support positive terms
#   - Wrap in negative field!

sub new {
  my ($class, $term_id) = @_;
  bless {
    term_id => $term_id
  }, $class;
};

sub type {
  'field_id';
};


sub is_leaf {
  1;
};

sub is_negative {
  0;
};

sub operands {
  return [];
};


sub term_id {
  $_[0]->{term_id};
};

sub optimize {
  my ($self, $segment) = @_;

  # Negative field
  if ($self->is_negative) {
    warn 'Fields are not allowed to be negative';
    return;
  };

  # Positive field
  my $query = Krawfish::Corpus::FieldID->new(
    $segment,
    $self->term_id
  );

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  return $query;
};


sub to_koral_fragment {
  ...
};

sub is_nowhere {
  0;
};

sub to_string {
  return '#' . $_[0]->{term_id};
};

1;

__END__
