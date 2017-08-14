package Krawfish::Posting::Aggregate::Fields;
use strict;
use warnings;

# TODO:
#   This should be part of Koral::Result!

sub new {
  my $class = shift;
  bless {
    fields => {},
    cache => [],
    freq => 0
  }, $class;
};

sub incr_doc {
  my ($self, $key_id, $field_id) = @_;

  my $fields = $self->{fields};

  # Field may already exist
  my $field_key_freq = ($fields->{$key_id} //= {});
  my $field_freq = ($field_key_freq->{$field_id} //= [0,0]);

  # Increase doc frequency for the key
  $field_freq->[0]++;

  # Remember
  push @{$self->{cache}}, $field_freq;
};


sub incr_match {
  $_[0]->{freq}++;
};


sub flush {
  my $self = shift;

  if ($self->{freq}) {
    foreach my $field_freq (@{$self->{cache}}) {
      $field_freq->[1] += $self->{freq};
    };

    $self->{cache} = [];
    $self->{freq} = 0;
  };
};


sub to_terms {
  my ($self, $dict) = @_;

  # Get fields
  my $fields = $self->{fields};
  my %fields = ();

  # Iterate over field identifier
  foreach my $field_id (keys %$fields) {
    my $field_term = $dict->term_by_term_id($field_id);

    $field_term =~ s/^!//;
    my $aggr = ($fields{$field_term} //= {});

    # Get facets for field
    my $values = $fields->{$field_id};
    foreach my $value (keys %$values) {
      my $facet = $dict->term_by_term_id($value);
      $facet =~ s/^\+$field_term://;

      $aggr->{$facet} = $values->{$value};
    };
  };

  $self->{fields_terms} = \%fields;

  $self;
};


sub to_string {
  my $self = shift;
  if ($self->{fields_terms}) {
    my $str = 'facets=';

    my $fields = $self->{fields_terms};

    foreach my $field (sort keys %$fields) {
      $str .= $field . ':';

      my $values = $fields->{$field};
      foreach (sort keys %$values) {
        $str .= $_;
        my $freq = $values->{$_};
        $str .= '['.$freq->[0].','.$freq->[1].'],';
      };
      chop $str;
      $str .= ';';
    };
    chop $str;
    return $str;
  };
  return '';
};


1;


__END__
