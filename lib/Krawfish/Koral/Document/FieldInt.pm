package Krawfish::Koral::Document::FieldInt;
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;

sub new {
  my $class = shift;
  bless {
    key => shift,
    value => shift
  }, $class;
};

sub type {
  'int';
};

# Get key_value combination
sub term_id {
  $_[0]->{key_value_id};
};


# Get key identifier
sub key_id {
  $_[0]->{key_id};
};


sub value {
  $_[0]->{value};
};


sub identify {
  my ($self, $dict) = @_;

  my $key  = '!' . $self->{key};
  my $term = '+' . $self->{key} . ':' . $self->{value};

  # Get key term_id
  my $term_id = $dict->term_id_by_term($key);

  # Not given yet
  if (defined $term_id) {

    $self->{key_id} = $term_id;

    # Get term identifier
    $term_id = $dict->term_id_by_term($term);

    # Term identifier does not exist
    if (defined $term_id) {
      $self->{key_value_id} = $term_id;
    }

    else {
      $self->{key_value_id} = $dict->add_term($term);
    };
  }

  else {
    $self->{key_id} = $dict->add_term($key);
    $self->{key_value_id} = $dict->add_term($term);
  };
  return $self;
};


sub to_string {
  my $self = shift;
  unless ($self->{key_id}) {
    return squote($self->{key}) . '=' . $self->{value};
  };
  return $self->{key_id} . '=' . $self->{key_value_id} . '(' . $self->{value} . ')';
};




1;
