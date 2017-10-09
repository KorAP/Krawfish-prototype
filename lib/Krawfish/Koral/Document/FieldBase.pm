package Krawfish::Koral::Document::FieldBase;
use Krawfish::Log;
use Role::Tiny;
use warnings;
use strict;

use constant DEBUG => 1;

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


sub inflate {
  ...
};


sub sortable {
  $_->{sortable};
};

1;
