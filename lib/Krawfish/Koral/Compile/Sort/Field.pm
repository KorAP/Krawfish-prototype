package Krawfish::Koral::Compile::Sort::Field;
use Krawfish::Compile::Segment::Sort::Field;
use Krawfish::Koral::Compile::Sort::No;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    field => shift, # Is a Koral::Compile::Type::Key / KeyID
    desc => shift
  }, $class;
};

sub type {
  'field';
};

sub field {
  return $_[0]->{field};
};

sub desc {
  return $_[0]->{desc};
};

sub optimize {
  my ($self, $segment) = @_;

  return Krawfish::Compile::Segment::Sort::Field->new(
    $segment,
    $_[0]->{field}->term_id,
    $_[0]->{desc}
  );
};



sub identify {
  my ($self, $dict) = @_;
  my $field = $self->{field}->identify($dict);

  # TODO:
  #   In case the requested field is not sortable,
  #   ignore this sortable field as well!
  #   But add a warning to the user!

  # Field does not exist in the dictionary
  unless ($field) {
    return Krawfish::Koral::Compile::Sort::No->new(
      $self->{field}, $self->{desc}
    );
  };

  $self->{field} = $field;

  return $self;
};


sub to_string {
  my ($self, $id) = @_;
  my $str = 'field=' . $self->{field}->to_string($id);
  $str .= ($self->{desc} ? '>' : '<');
  $str;
};


1;
