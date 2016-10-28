package Krawfish::Index::Term;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $term = shift;

  my @self;

  # TODO: Support escaping!
  if ($term =~ m!^(?:([^:\/]+?):)? # 1 Field
                 (<>|[\<\>\@])?    # 2 Prefix
                 ([^\/]+?)         # 3 Foundry or Key
                 (?:
                   (?:/([^\=]+?))? # 4 Layer
                   =([^\:]+?)      # 5 Key
                   (?:\:(.+))?     # 6 Value
                 )?
                 $!x) {

    # Key is defined
    if ($5) {
      @self = ($1, $2, $3, $4, $5, $6);
    }

    # The foundry is the key
    else {
      @self = ($1, $2, undef, undef, $3);
    };
  }

  # Term is not valid
  else {
    warn 'Invalid term structure: ' . $term;
    return;
  };

  bless \@self, $class;
};

sub field {
  if ($_[1]) {
    $_[0]->[0] = $_[1];
  };
  $_[0]->[0];
};

sub prefix {
  if ($_[1]) {
    $_[0]->[1] = $_[1];
  };
  $_[0]->[1];
};

sub type {
  my $self = shift;
  return 'token' unless $self->prefix;
  return 'span' if $self->prefix eq '<>';
  return 'attribute' if $self->prefix eq '@';
  return 'relation';
};

sub foundry {
  if ($_[1]) {
    $_[0]->[2] = $_[1];
  };
  $_[0]->[2];
};

sub layer {
  if ($_[1]) {
    $_[0]->[3] = $_[1];
  };
  $_[0]->[3];
};

sub key {
  if ($_[1]) {
    $_[0]->[4] = $_[1];
  };
  $_[0]->[4];
};

sub value {
  if ($_[1]) {
    $_[0]->[5] = $_[1];
  };
  $_[0]->[5];
};

sub to_koral_query_fragment {
  my $self = shift;
  my $hash = {
    '@type' => 'koral:term',
    'key' => $self->key,
  };
  $hash->{foundry} = $self->foundry if $self->foundry;
  $hash->{layer} = $self->layer if $self->layer;
  $hash->{value} = $self->value if $self->value;

  return {
    '@type' => 'koral:' . $self->type,
    'wrap' => $hash
  };
};

1;
