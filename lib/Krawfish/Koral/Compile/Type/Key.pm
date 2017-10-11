package Krawfish::Koral::Compile::Type::Key;
use Krawfish::Util::Constants qw':PREFIX';
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

# TODO:
#   Make this an inflatable interface

sub new {
  my ($class, $term, $term_id) = @_;

  bless {
    term => $term,
    term_id => $term_id
  }, $class;
};


# Identify key ids
sub identify {
  my ($self, $dict) = @_;

  return if $self->{term_id};

  # Get term from dictionary
  my $term_id = $dict->term_id_by_term(KEY_PREF . $self->{term});

  # Term does not exist!
  return unless $term_id;

  # Return identifier
  $self->{term_id} = $term_id;

  return $self;
};


sub term {
  $_[0]->{term};
};


sub term_id {
  $_[0]->{term_id};
};


sub to_string {
  my $self = shift;
#  warn 'DEPRECATED';
  if ($self->{term}) {
    return squote($self->{term});
  };
  return '#' . $self->{term_id};
};


sub to_id_string {
  my $self = shift;
  return '#' . $self->{term_id} if $self->{term_id};
};


sub to_term_string {
  my $self = shift;
  if ($self->{term}) {
    return squote($self->{term});
  };
};


1;
