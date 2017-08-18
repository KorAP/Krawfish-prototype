package Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    field => shift,
    desc => shift
  }, $class;
};

sub field {
  return $_[0]->{field};
};

sub identify {
  my ($self, $dict) = @_;
  my $field = $self->{field}->identify($dict);

  # TODO:
  #   In case the requested field is not sortable,
  #   ignore this sortable field as well!
  #   But add a warning to the user!

  # Field does not exist in the dictionary
  return unless $field;

  $self->{field} = $field;

  return $self;
};

sub to_string {
  my $str = 'field=' . $_[0]->{field}->to_string;
  $str .= ($_[0]->{desc} ? '>' : '<');
  $str;
};

1;
