package Krawfish::Koral::Result::Group::Fields;
use Krawfish::Util::PatternList qw/pattern_list/;
use Data::Dumper;
use Role::Tiny::With;
use Krawfish::Util::Bits;
use Krawfish::Log;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

with 'Krawfish::Koral::Result::Inflatable';
with 'Krawfish::Koral::Result::Group';

use constant DEBUG => 0;

# Group on a sequence of field values

# TODO:
#   In addition to the group name
#   create a signature that is universal for each group
#   Probably by creating a group-class with as_sig() and as_list()

sub new {
  my $class = shift;
  bless {
    field_keys => shift,
    flags => shift,
    cache => undef,
    group => {},
    freq => 0
  }, $class;
};


# Increment on a pattern, which is an ordered list of strings
sub incr_doc {
  my ($self, $pattern, $flags) = @_;

  # Store all patterns in a cache
  $self->{cache} = [

    # This is an array of patterns
    pattern_list(@$pattern)
  ];

  $self->{cache_flags} = $flags;
};


# increment on match
sub incr_match {
  $_[0]->{freq}++;

  if (DEBUG) {
    print_log('p_g_fields', 'Increment match frequency');
  };
};


# Flush cache
sub flush {
  my $self = shift;

  if ($self->{freq}) {

    # Iterate over all lists
    foreach my $group (@{$self->{cache}}) {

      # This uses an array as a key ...
      # probably should be serialized differently
      my $group_name = join('_', @$group);

      my $group_value = ($self->{group}->{$group_name} //= {});

      if (DEBUG) {
        print_log('p_g_fields', 'Group on name ' . $group_name);
      };

      my $freq = ($group_value->{$self->{cache_flags}} //= [0,0]);

      # Increment doc freq
      $freq->[0]++;

      # Increment match freq
      $freq->[1] += $self->{freq};
    };

    $self->{cache} = undef;
    $self->{cache_flags} = undef;
    $self->{freq} = 0;
  };
};


# On finish, flush the cache
sub on_finish {
  $_[0]->flush;
  $_[0];
};


# Merge groups
sub merge {
  my ($self, $group) = @_;
  my $est_group = $self->{group};
  my $new_group = $group->{group};

  # Get groups
  foreach my $signature (keys %{$new_group}) {
    $est_group->{$signature} //= {};

    if (DEBUG) {
      print_log('p_g_fields','Result: ' . Dumper $new_group);
    };

    # Iterate over all existing groups
    foreach my $flag (keys %{$new_group->{$signature}}) {

      my $value = ($est_group->{$signature}->{$flag} //= [0,0]);
      my $freq = $new_group->{$signature}->{$flag};

      $value->[0] += $freq->[0];
      $value->[1] += $freq->[1];
    };
  };
};



# Translate this to terms
sub inflate {
  my ($self, $dict) = @_;
  my $field_keys = $self->{field_keys};

  # $self->{field_terms} = [];
  $self->{group_terms} = [];

  # Inflate head line
  foreach my $field (@{$field_keys}) {

    $field->identify($dict);

    # my $field_term = $dict->term_by_term_id($field_id);

    # $field_term =~ s/^!//;
    # TODO:
    #   This may be a direct feature of the dictionary
    # $field_term = substr($field_term, 1);

    # push @{$self->{field_terms}}, $field_term;
  };

  # Inflate groups
  foreach my $group (sort keys %{$self->{group}}) {
    my @group = ();
    my $i = 0;
    foreach my $term_id (split('_', $group)) {

      # Term is defined at the position
      if ($term_id != 0) {

        # Retrieve term
        my $term = $dict->term_by_term_id($term_id);
        my $field_term = $self->{field_keys}->[$i]->term;

        # TODO:
        #   This may be a direct feature of the dictionary
        $term =~ s/^.$field_term://;

        push @group, $term;
      }
      else {
        push @group, '';
      };

      # Move to next field
      $i++;
    };

    push @{$self->{group_terms}}, [join('_',@group), $self->{group}->{$group}];
  };

  return $self;
};


# Generate class ordering
sub _to_classes {
  my $self = shift;
  my @classes;

  my $groups = $self->{group_terms};

  # Iterate over group names
  foreach my $group (@$groups) {

    # Group has the structure [sig,{flag=>[freq]}]

    my $sig = $group->[0];
    my $flags = $group->[1];

    # Iterate over all flags
    foreach my $flag (keys %$flags) {

      # Iterate over classes
      foreach my $class (flags_to_classes($flag)) {

        # Store all data below class information
        $classes[$class] //= {};
        my $field = ($classes[$class]->{$sig} //= [0,0]);
        $field->[0] += $flags->{$flag}->[0];
        $field->[1] += $flags->{$flag}->[1];
      };
    };
  };

  return \@classes;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $str = '[fields=[';

  $str .= join(',', map { $_->to_string($id) } @{$self->{field_keys}});

  $str .= '];';

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    $str .= $i == 0 ? 'total' : 'inCorpus-' . $i;
    $str .= ':[';

    my $fields = $classes[$i];
    foreach my $group (sort keys %{$fields}) {

      # serialize frequencies
      $str .= squote($group) . ':[';
      $str .= $fields->{$group}->[0] . ',';
      $str .= $fields->{$group}->[1] . '],';
    };
    chop $str;
    $str .= ']';
    $str .= ',';
  };

  chop $str;
  return $str . ']';
};


# Key for KQ serialization
sub key {
  'fields'
};


# Serialize KQ
sub to_koral_fragment {
  my $self = shift;

  my $group = {
    '@type'   => 'koral:groupBy',
    'groupBy' => 'groupBy:fields',
    'fields'  => [map { $_->term } @{$self->{field_keys}}],
    'sortBy' => undef # Not yet sorted
  };

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    my $corpus = ($group->{$i == 0 ? 'total' : 'inCorpus-' . $i} //= []);

    my $fields = $classes[$i];

    # TODO: The list should be sorted!
    foreach my $group (sort keys %{$fields}) {

      # serialize frequencies
      push @$corpus, {
        '@type' => 'koral:row',
        cols    => [split('_', $group)],
        docs    => $fields->{$group}->[0],
        matches => $fields->{$group}->[1]
      };
    };
  };

  return $group;
};

1;
