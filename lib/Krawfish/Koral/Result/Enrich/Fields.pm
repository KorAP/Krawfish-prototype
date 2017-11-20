package Krawfish::Koral::Result::Enrich::Fields;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';

# The fields are represented as Krawfish::Koral::Document::Field* objects!

sub new {
  my $class = shift;
  bless {
    fields => [@_]
  }, $class;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return 'fields:' . join(',', map {
    $_->to_string($id)
  } @{$self->{fields}});
};


# Inflate fields
sub inflate {
  my ($self, $dict) = @_;
  my $fields = $self->{fields};
  foreach (my $i = 0; $i < @$fields; $i++) {
    $self->{fields}->[$i] = $fields->[$i]->inflate($dict);
  };
  return $self;
};


# Key for enrichment
sub key {
  'fields';
};


# Serialize to KoralQuery
sub to_koral_fragment {
  my $self = shift;
  my @fields = ();
  foreach (@{$self->{fields}}) {
    push @fields, $_->to_koral_fragment;
  };

  return \@fields;
};


1;
