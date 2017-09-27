package Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Meta::Segment::Sort::Field;
use Krawfish::Koral::Meta::Sort::No;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    field => shift, # Is a Koral::Meta::Type::Key / KeyID
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

  return Krawfish::Meta::Segment::Sort::Field->new(
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
    return Krawfish::Koral::Meta::Sort::No->new(
      $self->{field}, $self->{desc}
    );
  };

  $self->{field} = $field;

  return $self;
};


sub to_string {
  my $str = 'field=' . $_[0]->{field}->to_string;
  $str .= ($_[0]->{desc} ? '>' : '<');
  $str;
};

1;
