package Krawfish::Posting::Aggregate::Fields;
use Krawfish::Log;
use strict;
use warnings;

# This remembers facets for multiple classes,
# both using ids and terms

# TODO:
#   The first field level should be initiated
#   beforehand, so it is not necessary to check
#   this level on each doc.

# TODO:
#   This should be part of Koral::Result!

# TODO:
#   It may be beneficial to deal with Koral::Type here,
#   so inflate() would be an action directly done in Koral::Type

# TODO:
#   Rename stringifications to aFields!

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    fields => {},
    cache => [],
    freq => 0
  }, $class;
};


# Increment the field frequency for each field in the current doc
sub incr_doc {
  my ($self, $key_id, $field_id) = @_;

  my $fields = $self->{fields};

  # Field may already exist
  my $field_key_freq = ($fields->{$key_id} //= {});
  my $field_freq = ($field_key_freq->{$field_id} //= [0,0]);

  # Increase doc frequency for the key
  # Maybe that's not necessary and can be done in flush
  $field_freq->[0]++;

  if (DEBUG) {
    print_log('p_a_fields', 'Increment doc frequency for #' . $key_id . '=#' . $field_id);
  };


  # Remember the frequency
  # The problem here is, that they are only loosely coupled to the field
  # frequency of the field. This may be problematic
  push @{$self->{cache}}, $field_freq;
};


# Increment the field frequency for each field per match
sub incr_match {
  $_[0]->{freq}++;

  if (DEBUG) {
    print_log('p_a_fields', 'Increment match frequency');
  };
};


# Flush all frequency information remembered
sub flush {
  my $self = shift;

  if ($self->{freq}) {
    foreach my $field_freq (@{$self->{cache}}) {
      $field_freq->[1] += $self->{freq};
    };

    $self->{cache} = [];
    $self->{freq} = 0;

    if (DEBUG) {
      print_log('p_a_fields', 'Flush field frequency for all remembered frequencies');
    };
  };
};


# Translate this to terms
sub inflate {
  my ($self, $dict) = @_;

  # Get fields
  my $fields = $self->{fields};
  my %fields = ();

  # Iterate over field identifier
  foreach my $field_id (keys %$fields) {

    # Request the term from the dictionary
    my $field_term = $dict->term_by_term_id($field_id);

    # Remove the term marker
    # TODO:
    #   this may be a direct feature of the dictionary instead
    $field_term =~ s/^!//;
    my $aggr = ($fields{$field_term} //= {});

    # Get facets for field
    my $values = $fields->{$field_id};
    foreach my $value (keys %$values) {

      # Get the 
      my $field = $dict->term_by_term_id($value);
      $field =~ s/^\+$field_term://;

      $aggr->{$field} = $values->{$value};
    };
  };

  $self->{fields_terms} = \%fields;

  $self;
};


sub to_string {
  my $self = shift;
  if ($self->{fields_terms}) {
    my $str = 'fields=';

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

  warn 'Please inflate before!';
  return '';
};


1;


__END__
