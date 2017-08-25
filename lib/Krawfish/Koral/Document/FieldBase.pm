package Krawfish::Koral::Document::FieldBase;
use Role::Tiny;
use warnings;
use strict;


# TODO:
#   Probably use Krawfish::Koral::Meta::Type::KeyID and
#   Krawfish::Koral::Meta::Type::Key.


sub new {
  my $class = shift;
  # key, value, key_id, key_value_id, sortable
  bless { @_ }, $class;
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
