package Krawfish::Koral::Document::FieldDate;
use warnings;
use strict;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Krawfish::Koral::Document::Field::Date;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Document::FieldBase';

use constant DEBUG => 0;

# Class for date fields

# TODO:
#   Move parts of it to Koral::Document::Field::Date!

# TODO:
#   Join this with
#   Krawfish::Koral::Corpus::Field::Date

# TODO:
#   Make value==from

sub type {
  'date';
};


sub new {
  my $class = shift;

  # key, value, key_id, key_value_id, sortable
  my $self = bless {
    @_
  }, $class;

  return unless $self->{value};

  # It's a range
  if (index($self->{value},RANGE_SEP) > -1) {

    # The range needs to be single string, so it's possible to
    # have multiple ranges!
    my ($from, $to) = split(RANGE_SEP, $self->{value});
    $self->{from}  = Krawfish::Koral::Document::Field::Date->new(
      key => $self->{key},
      value => $from
    );
    $self->{to}    = Krawfish::Koral::Document::Field::Date->new(
      key => $self->{key},
      value => $to
    );
    $self->{value} = $self->from->value_string . RANGE_SEP . $self->to->value_string;
  }

  # It's a single date
  else {

    $self->{from} = $self->{to} = Krawfish::Koral::Document::Field::Date->new(
      key => $self->{key},
      value => $self->{value}
    );

    $self->{value} = $self->from->value_string;
  };

  return $self;
};


# Get all range term identifier
sub range_term_ids {
  return $_[0]->{range_term_ids};
};



sub identify {
  my ($self, $dict) = @_;

  # This will check, if the field is
  # sortable
  return $self if $self->{key_id} && $self->{key_value_id};

  # Get or introduce new key term_id
  my $key = KEY_PREF . $self->{key};

  # THIS WILL STORE THE INFLATABLE STRING
  # (may not be necessary)
  $self->{key_id} = $dict->add_term($key);

  if (DEBUG) {
    print_log('k_doc_fdate', 'Check for sortability for ' . $self->{key_id});
  };

  # Set sortable
  if (my $collation = $dict->collation($self->{key_id})) {
    if (DEBUG) {
      print_log('k_doc_fdate', 'Field ' . $self->{key_id} . ' is sortable');
    };
    $self->{sortable} = 1;
  };

  # Get or introduce new key term_id
  my $term = DATE_FIELD_PREF . $self->{key} . ':' . $self->{value};
  $self->{key_value_id} = $dict->add_term($term);

  # Index more terms for range queries
  $self->{range_term_ids} = [];
  foreach ($self->to_range_terms) {
    push @{$self->{range_term_ids}}, $dict->add_term($_);
  };

  return $self;
};


# Inflate field
# The date is stored uncompressed
sub inflate {
  my ($self, $dict) = @_;

  # Key id not available
  return unless $self->{key_id};

  # Get term from term id
  $self->{key} = substr(
    $dict->term_by_term_id($self->{key_id}),
    1
  );

  return $self;
};


# Stringification
#   Identical to date
sub to_string {
  my ($self, $id) = @_;

  if (!$self->{key} || ($id && $self->{key_id})) {
    return '#' . $self->key_id . '=' . '#' .  $self->{key_value_id} . '(' . $self->{value} . ')';
  };
  return squote($self->key) . '=' . $self->value;
};


# In case it's a range
sub from {
  $_[0]->{from};
};


sub to {
  $_[0]->{to};
};


sub to_range_terms {
  my $self = shift;
  if ($self->{from}->value_string eq $self->{to}->value_string) {
    return $self->{from}->to_range_terms;
  };

  warn '!!!';
  return;
};


1;
