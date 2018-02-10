package Krawfish::Koral::Result::Aggregate::Fields;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;
use Krawfish::Util::Bits;
use Krawfish::Util::Constants qw/:PREFIX/;

with 'Krawfish::Koral::Result::Inflatable';
with 'Krawfish::Koral::Result::Aggregate';

# This remembers facets for multiple classes,
# both using ids and terms

# TODO:
#   The first field level should be initiated
#   beforehand, so it is not necessary to check
#   this level on each doc.

# TODO:
#   This should accept an order field, to reconstruct the requested
#   field order after aggregation!

# TODO:
#   It may be beneficial to deal with Koral::Type here,
#   so inflate() would be an action directly done in Koral::Type

# TODO:
#   Rename stringifications to aFields!

# TODO:
#   Support flags in constructor

use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;
  bless {
    flags  => shift,
    fields => {},
    cache  => [],
    freq   => 0
  }, $class;
};


# Increment the field frequency for each field in the current doc
sub incr_doc {
  my ($self, $key_id, $field_id, $flags) = @_;

  # TODO:
  #   It may be easier to create the structure
  #   in flush(), similar to K::R::Group::Fields

  # Structure is
  # {
  #   field1 => {
  #     key1 => {
  #       flag1 => [0,0],
  #       flag2 => [0,0]
  #     }
  #     key2 => {
  #       flag1 => [0,0],
  #       flag2 => [0,0]
  #     }
  #   },
  #   field2 => {
  #     key1 => {
  #       flag1 => [0,0],
  #       flag2 => [0,0]
  #     }
  #   }
  # }

  # Get fields per flags
  my $fields = $self->{fields};

  # Field may already exist
  my $field_key_freq = ($fields->{$key_id} //= {});

  # Initialize frequency
  my $field_freq = ($field_key_freq->{$field_id} //= {});

  # Initialize frequency
  my $field_flag_freq = ($field_freq->{$flags} //= [0,0]);

  if (DEBUG) {
    print_log(
      'p_a_fields',
      "Increment doc frequency for #" . $key_id . '=#' . "$field_id for flag $flags"
    );
  };

  # Remember the frequency
  # The problem here is, that they are only loosely coupled to the field
  # frequency of the field. This may be problematic
  push @{$self->{cache}}, $field_flag_freq;
};


# Increment the field frequency for each field per match
sub incr_match {
  $_[0]->{freq}++;

  if (DEBUG) {
    print_log('p_a_fields', 'Increment match frequency');
  };
};


# Flush all frequency information remembered
# per document
sub flush {
  my $self = shift;

  if ($self->{freq}) {

    # Iterate over cached frequency object
    foreach my $field_flag_freq (@{$self->{cache}}) {

      if (DEBUG) {
        print_log(
          'p_a_fields',
          'Increase frequency on cached references '.
            'with ' . $self->{freq}
        );
      };

      # Increment doc freq
      $field_flag_freq->[0]++;

      # Increment match freq
      $field_flag_freq->[1] += $self->{freq};
    };

    $self->{freq} = 0;
    $self->{cache} = [];

    if (DEBUG) {
      print_log('p_a_fields', 'Flush field frequency for all remembered frequencies');
    };
  };
};


# On finish flush the cache
sub on_finish {
  $_[0]->flush;
  $_[0];
};


# Merge aggregation data
sub merge {
  my ($self, $aggr) = @_;

  foreach my $field (keys %{$aggr->{fields}}) {
    $self->{fields}->{$field} //= {};

    foreach my $key (keys %{$aggr->{fields}->{$field}}) {
      my $flags = $aggr->{fields}->{$field}->{$key};
      my $self_flags = ($self->{fields}->{$field}->{$key} //= {});

      foreach my $flag (keys %$flags) {
        $self_flags->{$flag} //= [0,0];
        $self_flags->{$flag}->[0] += $flags->{$flag}->[0];
        $self_flags->{$flag}->[1] += $flags->{$flag}->[1];
      }
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
    $field_term = substr($field_term,1); # ~ s/^!//;
    my $aggr = ($fields{$field_term} //= {});

    # Get facets for field
    my $values = $fields->{$field_id};
    foreach my $value (keys %$values) {

      # Get the field term
      my $field = $dict->term_by_term_id($value);

      # Remove the first character
      # TODO:
      #   This may be a direct feature of the dictionary instead
      $field =~ s/^.$field_term://;

      # These are flag sorted values!
      $aggr->{$field} = $values->{$value};
    };
  };

  $self->{fields_terms} = \%fields;
  $self;
};


# Generate class ordering
sub _to_classes {
  my $self = shift;

  # Order field terms by classes
  # Doing this beforehand on_finish would be costly
  my @classes;

  my $fields = $self->{fields_terms};

  # Iterate over fields
  foreach my $key (keys %$fields) {

    # Iterate over field values
    foreach my $field (keys %{$fields->{$key}}) {

      # Iterate over flags
      my $freqs = $fields->{$key}->{$field};
      foreach my $flag (keys %$freqs) {

        # Iterate over classes
        foreach my $class (flags_to_classes($flag)) {

          # Store all data below class information
          $classes[$class] //= {};
          my $key = ($classes[$class]->{$key} //= {});
          my $field = ($key->{$field} //= [0,0]);
          $field->[0] += $freqs->{$flag}->[0];
          $field->[1] += $freqs->{$flag}->[1];
        };
      };
    };
  };

  return \@classes;
};



# Stringification
sub to_string {
  my ($self, $ids) = @_;

  my $str = '[fields=';

  # IDs not supported
  if ($ids) {
    # warn 'ID based stringification currently not supported';
    return $str . '#?]';
  };

  # No terms yet
  unless ($self->{fields_terms}) {
    # warn 'ID based stringification currently not supported';
    return $str . '#?]';
  };

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    $str .= $i == 0 ? 'total' : 'inCorpus-' . $i;
    $str .= ':[';

    my $fields = $classes[$i];
    foreach my $field (sort keys %$fields) {
      $str .= $field . '=';
      my $values = $fields->{$field};
      foreach (sort keys %$values) {
        $str .= $_ . ':';
        my $freq = $values->{$_};
        $str .= '['.$freq->[0].','.$freq->[1].'],';
      };
      chop $str;
      $str .= ';';
    };
    chop $str;
    $str .= '];';
  };
  chop $str;

  return $str . ']';
};


# Key to add to KoralQuery
sub key {
  'fields';
};


# Serialize to KQ
sub to_koral_fragment {
  my $self = shift;
  my $aggr = {
    '@type' => 'koral:aggregation',
    'aggregation' => 'aggregation:fields'
  };

  # No terms yet
  unless ($self->{fields_terms}) {
    warn 'ID based stringification currently not supported';
    return;
  };

  # TODO:
  #   Use order field to recreate initial field order!

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    my $per_field = $aggr->{$i == 0 ? 'total' : 'inCorpus-' . $i} = {};
    my $fields = $classes[$i];

    # Store per field
    foreach my $field (sort keys %$fields) {

      # Get values
      my $values = $fields->{$field};

      # Iterate over values
      foreach (keys %$values) {
        my $freq = $values->{$_};
        my $per_value = $per_field->{$field} //= {};
        $per_value->{$_} = {
          docs => $freq->[0],
          matches => $freq->[1]
        };
      };
    };
  };

  return $aggr;
};

1;


__END__
