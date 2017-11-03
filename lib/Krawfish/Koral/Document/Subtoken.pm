package Krawfish::Koral::Document::Subtoken;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Koral::Document::Annotation;
use warnings;
use strict;

# This represents a single token in a forward index

# THIS IS VERY SIMILAR TO Krawfish::Posting::Forward

# This should be an inflatable as well!

sub new {
  my $class = shift;
  my %hash = @_;
  $hash{anno} //= [];
  bless \%hash, $class;
};


# TODO: This is just temporary
sub new_by_term_id {
  my $class = shift;
  bless {

    # TODO: Differ between compressed an uncompressed
    preceding_enc => shift,
    subterm_id => shift,
    anno => []
  }, $class;
};


# Preceeding bytes of the subterm
sub preceding {
  $_[0]->{preceding} // '';
};


sub preceding_enc {
  $_[0]->{preceding_enc} // '';
};


# The subterm surface
sub subterm {
  $_[0]->{subterm};
};


# Subterm id
sub subterm_id {
  $_[0]->{subterm_id};
};


# Alias
sub term_id {
  $_[0]->{subterm_id};
};


sub annotations {
  $_[0]->{anno};
};


# Add annotations
sub add_annotation {
  my $self = shift;
  push @{$self->{anno}}, Krawfish::Koral::Document::Annotation->new(@_);
};


# Inflate
sub inflate {
  my ($self, $dict) = @_;
  $self->{preceding} = $self->{preceding_enc};
  $self->{subterm} = $dict->term_by_term_id($self->{subterm_id});
  return $self;
};


# Identify terms
sub identify {
  my ($self, $dict) = @_;

  # This is the final subtoken that's only
  # required for preceding bytes

  $self->{preceding_enc} = $self->{preceding};

  return $self unless $self->{subterm};

  my $term = SUBTERM_PREF . $self->{subterm};
  $self->{subterm_id} = $dict->add_term($term);

  foreach (@{$self->{anno}}) {
    $_->identify($dict);
  };

  return $self;
};



# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $str = '<' . ($id ? $self->preceding_enc : $self->preceding) . '>';
  $str .= '[';

  if ($id) {
    $str .= $self->{subterm_id} ? '#' . $self->{subterm_id} : '##';
  }

  else {

    # Subterm defined
    if ($self->{subterm}) {
      $str .= squote($self->{subterm})
    }

    # Not yet inflated!
    elsif ($self->{subterm_id}) {

      # warn 'Subtoken ' . $self->{subterm_id} . ' is not yet inflated!';
      $str .= "'?'";
    }
    else {
      $str .= "''";
    };
  };

  if (@{$self->{anno}}) {
    $str .= ';' . join(';', map { $_->to_string($id) } (@{$self->{anno}}));
  };

  return "$str]";
};


1;
