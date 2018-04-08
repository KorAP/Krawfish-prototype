package Krawfish::Koral::Document::FieldBase;
use Krawfish::Log;
use Role::Tiny;
use warnings;
use strict;

use constant DEBUG => 0;

with 'Krawfish::Koral::Result::Inflatable';

requires qw/identify
            type
            sortable/;

# TODO:
#   Probably use Krawfish::Koral::Compile::Type::KeyID and
#   Krawfish::Koral::Compile::Type::Key.

sub new {
  my $class = shift;
  # key, value, key_id, key_value_id, sortable

  my $self = bless { @_ }, $class;

  return $self;
};

sub key_id {
  $_[0]->{key_id};
};


sub key {
  $_[0]->{key};
};

# Get key_value combination
sub term_id {
  $_[0]->{key_value_id};
};

sub value {
  $_[0]->{value};
};


sub sortable {
  $_->{sortable};
};



sub to_koral_fragment {
  my $self = shift;

  unless ($self->key) {
    warn 'Inflate!';
    return;
  };

  return {
    '@type' => 'koral:field',
    'type' => 'type:' . $self->type,
    # $self->type eq 'store' ? 'string' : $self->type
    'key' => $self->key,
    'value' => $self->value
  };
};



1;
