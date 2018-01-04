package Krawfish::Koral::Document::Annotation;
use warnings;
use strict;
use Krawfish::Util::String qw/squote/;
use Role::Tiny;

with 'Krawfish::Koral::Document::Term';
with 'Krawfish::Koral::Result::Inflatable';

# Accepts a Krawfish::Koral::Query::Term object
#
# TODO:
#   May as well only accept a term_id etc.
#   and needs to be inflated
sub new {
  my $class = shift;
  bless {
    term => shift,
    data => [@_]
  }, $class;
};


# Get data array
sub data {
  $_[0]->{data}
};



# Stringify annotation
sub to_string {
  my $self = shift;
  my $str = '';

  if ($self->{term_id}) {
    $str .= $self->{term_id};
  }

  else {
    $str .= squote($self->{term}->to_neutral);
  };
  return $str . '$' . join(',',  @{$self->{data}});
};


# Turn the Annotation into a koral fragment
sub to_koral_fragment {
  return $_[0]->term->to_koral_fragment;
};


1;
