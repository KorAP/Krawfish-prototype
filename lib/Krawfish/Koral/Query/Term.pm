package Krawfish::Koral::Query::Term;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Term;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;

# TODO: Support escaping! Especially for regex!

use constant DEBUG => 0;

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
                     \s*(\!?[=~])\s*   # 5 Operator
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
    };

    # Term is null
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
    return $_[0];
  };
  $_[0]->[2];
};


# Layer of the term
sub layer {
  if ($_[1]) {
    $_[0]->[3] = $_[1];
    return $_[0];
  };
  $_[0]->[3];
};

# Operation
sub match {
  if ($_[1]) {
    $_[0]->[4] = $_[1];
    return $_[0];
  };
  $_[0]->[4] // '=';
};


# Key of the term
sub key {
  if ($_[1]) {
    $_[0]->[5] = $_[1];
    return $_[0];
  };
  $_[0]->[5];
};

# Value of the term
sub value {
  if ($_[1]) {
    $_[0]->[6] = $_[1];
    return $_[0];
  };
  $_[0]->[6];
};


sub is_regex {
  return index($_[0]->match, '~') == -1 ? 0 : 1;
};

# Create koral fragment
sub to_koral_fragment {
  my $self = shift;

  my $hash = {
    '@type' => 'koral:term',
  };

  return $hash if $self->is_null;
  $hash->{key} = $self->key,
  $hash->{foundry} = $self->foundry if $self->foundry;
  $hash->{layer} = $self->layer if $self->layer;
  $hash->{value} = $self->value if $self->value;

  # TODO: REGEX!

  return $hash;
};

sub to_string {
  my $self = shift;

  if ($self->is_null) {
    return 0
  };

  my $str = '';

  if ($self->foundry) {
    $str .= $self->foundry;
    if ($self->layer) {
      $str .= '/' . $self->layer;
    };
    if ($self->key) {
      $str .= $self->match ? $self->match : '=';
    };
  }
  else {
    if ($self->is_negative) {
      $str .= '!';
    }
    elsif ($self->is_regex) {
      $str .= '/';
      $str .= $self->key;
      if ($self->value) {
        $str .= ':' . $self->value;
      };
      $str .= '/';
      return $str;
    }
  };
  $str .= $self->key;
  if ($self->value) {
    $str .= ':' . $self->value;
  };

  $str;
};

sub term {
  my $self = shift;
  return if $self->is_null;

  my $str = $self->field // '';
  if ($str) {
    $str .= ':';
  };
  $str .= $self->prefix if $self->prefix;
  my $term = $self->to_string;
  if ($self->match ne '=') {
    $term =~ s/!?[=~]/=/i;
  };
  if ($self->is_regex) {
    $term =~ s!^/!!;
    $term =~ s!/$!!;
  };
  return $str . $term;
};

sub term_escaped {
  my $self = shift;
  my $term = $self->term;
  if ($term =~ m!^((?:[^:]+?\:)?(?:[^/]+?\/)?(?:[^=]+?)\=)(.+?)$!) {
    return quotemeta($1). $2;
  };
  return $term;
};

sub plan_for {
  my $self = shift;
  my $index = shift;

  return if $self->is_negative || $self->is_null;

  # Expand regular expressions
  if ($self->is_regex) {

    # Get terms
    my $term = $self->term_escaped;
    my @terms = $index->dict->terms(qr/^$term$/);

    if (DEBUG) {
      print_log('regex', 'Expand /^' . $term . '$/');
      print_log('regex', 'to ' . substr(join(',',@terms),0,50));
    };

    return $self->builder->nothing unless @terms;

    my $builder = $self->builder;
    my $or = $builder->term_or(@terms)->plan_for($index);
    return $or;
  };

  return Krawfish::Query::Term->new($index, $self->term);
};

sub is_any {
  return 1 unless $_[0]->key;
  return;
};
sub is_optional { 0 };
sub is_null {
  return 1 unless $_[0]->key;
  return;
};
sub is_negative {
  $_[0]->match eq '!=' ? 1 : 0;
};
sub is_extended { 0 };
sub is_extended_right { 0 };
sub is_extended_left { 0 };
sub maybe_unsorted { 0 };

1;
