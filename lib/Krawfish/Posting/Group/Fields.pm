package Krawfish::Posting::Group::Fields;
use Krawfish::Util::PatternList qw/pattern_list/;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   In addition to the group name
#   create a signature that is universal for each group

sub new {
  my $class = shift;
  bless {
    field_keys => shift,
    cache => undef,
    group => {},
    freq => 0
  }, $class;
};


# Increment on a pattern, which is an ordered list of fields
sub incr_doc {
  my ($self, $pattern) = @_;

  # Store all patterns in a cache
  $self->{cache} = [
    pattern_list(@$pattern)
  ];
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

      # This uses an array as a key ... probably should be realized differently
      my $group_name = join('_',@$group);
      my $freq = ($self->{group}->{$group_name} //= [0,0]);

      if (DEBUG) {
        print_log('p_g_fields', 'Group on name ' . $group_name);
      };

      $freq->[0]++;
      $freq->[1] += $self->{freq};
    };

    $self->{cache} = undef;
    $self->{freq} = 0;
  };
};


sub inflate {
  my ($self, $dict) = @_;
  my $field_keys = $self->{field_keys};

  $self->{field_terms} = [];
  $self->{group_terms} = [];

  # Inflate head line
  foreach my $field_id (@{$field_keys}) {
    my $field_term = $dict->term_by_term_id($field_id);

    $field_term =~ s/^!//;

    push @{$self->{field_terms}}, $field_term;
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
        my $field_term = $self->{field_terms}->[$i];
        $term =~ s/^\+$field_term://;

        push @group, $term;
      }
      else {
        push @group, '';
      };

      # Move to next field
      $i++;
    };

    push @{$self->{group_terms}}, [\@group, @{$self->{group}->{$group}}];
  };

  return $self;
};


sub to_string {
  my $self = shift;
  my $str = 'gFields:[';

  if ($self->{field_terms}) {
    $str .= join(',', @{$self->{field_terms}}) . ':[';
    foreach my $group (@{$self->{group_terms}}) {
      $str .= join('|', @{$group->[0]}) . ':' . $group->[1] . ',' . $group->[2] . ';';
    };
  }
  else {
    $str .= join(',', map { '#' . $_ } @{$self->{field_keys}}) . ':[';
    foreach my $group (sort keys %{$self->{group}}) {
      $str .= $group .'=' . join(',', @{$self->{group}->{$group}}) . ';';
    };
  };
  chop $str;
  return $str . ']';
};


sub to_koral_query {
  # Create groups like
  # {
  #   "@type":"koral:collection",
  #   "groupedBy":"groupedBy:fields",   # or "aggregatedBy, "sortedBy"
  #   "labels":[...],
  #   "items":[
  #     {
  #       "@type":"koral:item",
  #       // "signature":"ab47mhjhjgfjuizgtzurzt",
  #       "cols":[...]
  #     }
  #   ]
  # }
  ...
};

1;
