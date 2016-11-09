package Krawfish::Koral::Query::Token;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Term;
use strict;
use warnings;

# TODO: Support multiple tokens in a token group!

sub new {
  my $class = shift;
  bless {
    term => shift
  }, $class;
};


# The term of the token (may need to be changed)
sub term {
  $_[0]->{term};
};

sub type { 'token' };

# Return Koral fragment
sub to_koral_fragment {
  my $self = shift;
  if ($self->term) {
    my $koral = Krawfish::Koral::Query::Term->new($self->term) or return {
      '@type' => 'koral:undefined'
    };
    return $koral->to_koral_fragment;
  };
  return {
    '@type' => 'koral:token'
  };
};


# Overwrite is any
sub is_any {
  return 1 unless $_[0]->term;
  return;
};


# Query planning
sub plan_for {
  my ($self, $index) = @_;

  # Token is null
  if ($self->is_null) {
    $self->error(000, 'Unable to search for null tokens');
    return;
  };

  # No term defined
  unless ($self->term) {
    $self->error(000, 'Unable to search for empty tokens');
    return;
  };

  # Create token query
  return Krawfish::Query::Token->new(
    $index,
    $self->term
  );
};


# Stringify
sub to_string {
  my $string = '[' . ($_[0]->term // '') . ']';
  if ($_[0]->is_null) {
    $string .= '{0}';
  }
  elsif ($_[0]->is_optional) {
    $string .= '?';
  };
  return $string;
};

1;
