package Krawfish::Index::Forward::Annotation;
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;

# TODO:
#   This should contain type, foundry, layer, key, value ... etc.

sub new {
  my $class = shift;
  bless {
    term => shift,
    data => [@_]
  }, $class;
};


sub term {
  $_[0]->{term};
};


sub data {
  $_[0]->{data}
};


sub identify {
  my ($self, $dict) = @_;
  my $term_id = $dict->term_id_by_term($self->{term});

  if (defined $term_id) {
    $self->{term_id} = $term_id;
  }
  else {
    $self->{term_id} = $dict->add_term($self->{term});;
  };

  return $self;
};


sub to_string {
  my $self = shift;
  my $str = '';

  if ($self->{term_id}) {
    $str .= $self->{term_id};
  }

  else {
    $str .= squote($self->{term});
  };
  return $str . '$' . join(',', @{$self->{data}});
};

1;
