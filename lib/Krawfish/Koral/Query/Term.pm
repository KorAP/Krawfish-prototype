package Krawfish::Koral::Query::Term;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Term;
use strict;
use warnings;

# TODO: Support escaping!
# TODO: Support regular expressions
# TODO: Support negation

sub new {
  my $class = shift;
  my $term = shift;

  my @self;

  if ($term) {
    if ($term =~ m!^(?:([^:\/]+?):)?   # 1 Field
                   (<>|[\<\>\@])?      # 2 Prefix
                   ([^\/]+?)           # 3 Foundry or Key
                   (?:
                     (?:/([^\=\!]+?))? # 4 Layer
                     \s*(\!?=)\s*      # 5 Operator
                     ([^\:]+?)         # 6 Key
                     (?:\:(.+))?       # 7 Value
                   )?
                   $!x) {

      # Key is defined
      if ($6) {
        @self = ($1, $2, $3, $4, $5, $6, $7);
      }

      # The foundry is the key
      else {
        @self = ($1, $2, undef, undef, undef, $3);
      };
    }

    # Term is not valid
    else {
      warn 'Invalid term structure: ' . $term;
      return;
    };
  };

  bless \@self, $class;
};

sub type { 'term' };

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

sub term_type {
  my $self = shift;
  return 'token'     unless $self->prefix;
  return 'span'      if $self->prefix eq '<>';
  return 'attribute' if $self->prefix eq '@';
  return 'relation';
};


# Foundry of the term
sub foundry {
  if ($_[1]) {
    $_[0]->[2] = $_[1];
  };
  $_[0]->[2];
};


# Layer of the term
sub layer {
  if ($_[1]) {
    $_[0]->[3] = $_[1];
  };
  $_[0]->[3];
};

# Operation
sub op {
  if ($_[1]) {
    $_[0]->[4] = $_[1];
  };
  $_[0]->[4];
};


# Key of the term
sub key {
  if ($_[1]) {
    $_[0]->[5] = $_[1];
  };
  $_[0]->[5];
};

# Value of the term
sub value {
  if ($_[1]) {
    $_[0]->[6] = $_[1];
  };
  $_[0]->[6];
};


# Create koral fragment
sub to_koral_fragment {
  my $self = shift;
  my $hash = {
    '@type' => 'koral:term',
    'key' => $self->key,
  };
  $hash->{foundry} = $self->foundry if $self->foundry;
  $hash->{layer} = $self->layer if $self->layer;
  $hash->{value} = $self->value if $self->value;

  return $hash;
};

sub to_string {
  my $self = shift;
  my $str = '';
  if ($self->foundry) {
    $str .= $self->foundry;
    if ($self->layer) {
      $str .= '/' . $self->layer;
    };
    if ($self->key) {
      $str .= $self->op ? $self->op : '=';
    };
  };
  $str .= $self->key;
  if ($self->value) {
    $str .= ':' . $self->value;
  };
  $str;
};

sub plan_for {
  my $self = shift;
  my $index = shift;
  return Krawfish::Query::Term->new($index, );
};

1;
