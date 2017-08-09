package Krawfish::Index::Forward::Subtoken;
use Krawfish::Index::Forward::Annotation;
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;

# This represents a single token in a forward index

sub new {
  my $class = shift;
  bless {
    preceding => shift,
    subterm => shift,
    anno => []
  }, $class;
};


# Preceeding bytes of the subterm
sub preceding {
  $_[0]->{preceding};
};


# The subterm surface
sub subterm {
  $_[0]->{subterm};
};

sub term_id {
  $_[0]->{subterm_id};
};


sub annotations {
  $_[0]->{anno};
};

# Add annotations
sub add_annotation {
  my $self = shift;
  push @{$self->{anno}}, Krawfish::Index::Forward::Annotation->new(@_);
};


sub identify {
  my ($self, $dict) = @_;

  # This is the final subtoken that's only required for preceding bytes
  return $self unless $self->{subterm};

  my $term = '*' . $self->{subterm};
  my $term_id = $dict->term_id_by_term($term);

  if (defined $term_id) {
    $self->{subterm_id} = $term_id;
  }
  else {
    $self->{subterm_id} = $dict->add_term($term);
  };

  foreach (@{$self->{anno}}) {
    $_->identify($dict);
  };

  return $self;
};

# Stringification
sub to_string {
  my $self = shift;
  my $str = ($self->{preceding} ? $self->{preceding} : '');
  $str .= '[';

  if ($self->{subterm_id}) {
    $str .= $self->{subterm_id};
  }
  else {
    $str .= squote($self->{subterm});
  };

  if (@{$self->{anno}}) {
    $str .= ';' . join(';', map { $_->to_string } (@{$self->{anno}}));
  };

  return "$str]";
};


1;
