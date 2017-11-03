package Krawfish::Koral::Result::Enrich::Terms;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';

# Represent all terms that are on surface per class

# TODO:
#   Probably use Term type utility, that is Inflatable and identifiable

sub new {
  my $class = shift;
  bless {
    term_ids => shift,
    terms => undef
  }, $class;
};


# Inflate term ids to terms
sub inflate {
  my ($self, $dict) = @_;

  # Initialize terms
  $self->{terms} = {};

  # Get term identifier
  my $data = $self->{term_ids};
  foreach my $key (keys %$data) {
    my @terms = ();
    foreach my $term_id (@{$data->{$key}}) {

      # Ignore gaps
      if ($term_id != 0) {
        push @terms, $dict->term_by_term_id($term_id);
      };
    };
    $self->{terms}->{$key} = \@terms
  };
  return $self;
};


# Key for serialization
sub key {
  'terms'
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = $self->key . ':';

  # Check if terms or ids need to be stringified
  my $data = $self->{terms} ? $self->{terms} :
    $self->{term_ids};

  # Iterate over all classes
  foreach my $class_nr (sort keys %{$data}) {
    $str .= '[' . $class_nr . ':';
    $str .= join(',', @{$data->{$class_nr}});
    $str .= ']';
  };

  return $str;
};


# Serialize KQ
sub to_koral_fragment {
  my $self = shift;
  my $terms = $self->{terms};

  my @terms = ();

  # Iterate over all classes
  foreach my $class_nr (sort keys %{$terms}) {
    push @terms, {
      classOut => $class_nr,
      terms => [map { substr($_, 1) } @{$terms->{$class_nr}} ]
    };
  };

  return \@terms;
};


1;
