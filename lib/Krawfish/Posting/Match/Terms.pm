package Krawfish::Posting::Match::Terms;
use strict;
use warnings;

# Represent all terms that are on surface per class

sub new {
  my $class = shift;
  bless {
    term_ids => shift,
    terms => undef
  }, $class;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'terms:';

  # Check if terms or ids need to be stringified
  my $data = $self->{terms} ? $self->{terms} :
    $self->{term_ids};

  # Iterate over all classes
  foreach my $class_nr (keys %{$data}) {
    $str .= '[' . $class_nr . ':';
    $str .= join(',', @{$data->{$class_nr}});
    $str .= ']';
  };

  return $str;
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


1;
