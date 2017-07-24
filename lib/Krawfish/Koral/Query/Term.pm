package Krawfish::Koral::Query::Term;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Term;
use Krawfish::Query::Filter;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;


# TODO: Support escaping! Especially for regex!

# TODO: Term building should be part of
#   a utility class Krawfish::Util::Koral::Term or so

# TODO:
#   Rename to_term to to_neutral!

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $term = shift;

  my %self;

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
        %self = (
          field => $1,
          prefix => $2,
          foundry => $3,
          layer => $4,
          operator => $5,
          key => $6,
          value => $7
        );
      }

      # The foundry is the key
      else {
        %self = (
          field => $1,
          prefix => $2,
          key => $3
        );
      };
    };

    # Term is null
  };

  bless \%self, $class;
};

sub type { 'term' };

sub is_leaf { 1 };

sub is_nothing { 0 };

sub operands {
  [];
};

sub remove_classes {
  $_[0];
};

# A term always spans exactly one token
sub min_span {
  return 0 if $_[0]->is_null;
  1;
};


# A term always spans exactly one token
sub max_span {
  return 0 if $_[0]->is_null;
  1;
};


sub field {
  if ($_[1]) {
    $_[0]->{field} = $_[1];
    return $_[0];
  };
  $_[0]->{field};
};


sub prefix {
  if ($_[1]) {
    $_[0]->{prefix} = $_[1];
    return $_[0];
  };
  $_[0]->{prefix};
};


sub term_type {
  my $self = shift;
  if ($_[0]) {
    if ($_[0] eq 'span') {
      $self->prefix('<>');
    }
    elsif ($_[0] eq 'attribute') {
      $self->prefix('@');
    }
    elsif ($_[0] eq 'relation') {

      # Todo: This doesn't respect
      # direction
      $self->prefix('>');
    };
    return $self;
  }
  else {
    return 'token'     unless $self->prefix;
    return 'span'      if $self->prefix eq '<>';
    return 'attribute' if $self->prefix eq '@';
    return 'relation';
  };
};


# Foundry of the term
sub foundry {
  if ($_[1]) {
    $_[0]->{foundry} = $_[1];
    return $_[0];
  };
  $_[0]->{foundry};
};


# Layer of the term
sub layer {
  if ($_[1]) {
    $_[0]->{layer} = $_[1];
    return $_[0];
  };
  $_[0]->{layer};
};


# Operation
sub match {
  my $self = shift;
  if ($_[0]) {
    my $match = shift;

    if ($match =~ s/^match://) {
      if ($match eq 'eq') {
        $match = '=';
      }
      elsif ($match eq 'ne') {
        $match = '!=';
      }
      else {
        warn 'Unknown match';
        return;
      }
    };

    $self->operator($match);
    return $self;
  };
  $self->operator;
};


# Operator of the term
sub operator {
  if ($_[1]) {
    $_[0]->{operator} = $_[1];
    return $_[0];
  };
  $_[0]->{operator} // '=';
};


# Key of the term
sub key {
  if ($_[1]) {
    $_[0]->{key} = $_[1];
    return $_[0];
  };
  $_[0]->{key};
};


# Value of the term
sub value {
  if ($_[1]) {
    $_[0]->{value} = $_[1];
    return $_[0];
  };
  $_[0]->{value};
};


sub is_regex {
  return index($_[0]->operator, '~') == -1 ? 0 : 1;
};


# Create koral fragment
sub to_koral_fragment {
  my $self = shift;

  my $hash = {
    '@type' => 'koral:term',
  };

  return $hash if $self->is_null;
  $hash->{key} = $self->key;
  $hash->{foundry} = $self->foundry if $self->foundry;
  $hash->{layer} = $self->layer if $self->layer;
  $hash->{value} = $self->value if $self->value;

  if ($self->operator eq '!=') {
    $hash->{match} = 'match:ne';
  };

  # TODO: REGEX!

  return $hash;
};


# TODO:
#   Support fragment, where a term string
#   may end with / or = to be used for
#   suggestions


# stringify term
sub to_string {
  my ($self, $fragment) = @_;

  return '-' if $self->is_null;

  my $str = '';

  if ($self->foundry) {
    $str .= $self->foundry;
    if ($self->layer) {
      $str .= '/' . $self->layer;
    };
    if ($self->key) {
      $str .= $self->operator;
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


sub to_neutral {
  return $_[0]->to_term;
};



sub to_term {
  my $self = shift;
  return if $self->is_null;

  my $str = $self->field // '';
  if ($str) {
    $str .= ':';
  };
  $str .= $self->prefix if $self->prefix;
  my $term = $self->to_string;
  if ($self->operator ne '=') {
    $term =~ s/!?[=~]/=/;
    $term =~ s/^!//;
  };
  if ($self->is_regex) {
    $term =~ s!^/!!;
    $term =~ s!/$!!;
  };
  return $str . $term;
};


sub to_term_escaped {
  my $self = shift;
  my $term = $self->to_term;
  if ($term =~ m!^((?:[^:]+?\:)?(?:[^/]+?\/)?(?:[^=]+?)\=)(.+?)$!) {
    return quotemeta($1). $2;
  };
  return $term;
};



sub normalize {
  my $self = shift;

  # return $self->is_negative || $self->is_null;
  return $self;
};


sub inflate {
  my ($self, $dict) = @_;

  # Do not inflate
  return $self unless $self->is_regex;

  # Get terms
  my $term = $self->to_term_escaped;

  print_log('kq_term', 'Inflate /^' . $term . '$/') if DEBUG;

  # Get terms from dictionary
  my @terms = $dict->terms(qr/^$term$/);

  if (DEBUG) {
    print_log('kq_term', 'Expand /^' . $term . '$/');
    print_log('kq_term', 'to ' . (@terms > 0 ? substr(join(',', @terms), 0, 50) : '[0]'));
  };

  # Build empty term instead of nothing
  return $self->builder->nothing unless @terms;

  # TODO:
  #   Use refer?
  return $self->builder->bool_or(@terms)->normalize;
};



sub optimize {
  my ($self, $index) = @_;
  return Krawfish::Query::Term->new($index, $self->to_term);
};


sub is_any {
  return 0;
};

sub is_optional {
  0
};

sub is_null {
  return 1 unless $_[0]->key;
  return;
};


sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    my $neg = shift;

    if ($neg && $self->match eq '=') {
      $self->match('!=');
    }
    elsif (!$neg && $self->match eq '!=') {
      $self->match('=');
    };
  };
  $self->match eq '!=' ? 1 : 0;
};



sub is_extended { 0 };
sub is_extended_right { 0 };
sub is_extended_left { 0 };
sub maybe_unsorted { 0 };


sub from_koral {
  my $class = shift;
  my $kq = shift;
  my $term = $class->new;
  $term->foundry('' . $kq->{foundry}) if $kq->{foundry};
  $term->layer('' . $kq->{layer}) if $kq->{layer};
  $term->key('' . $kq->{key}) if $kq->{key};
  $term->value('' . $kq->{value}) if $kq->{value};
  $term->match('' . $kq->{match}) if $kq->{match};

  # TODO: Support deserialization of regex!
  return $term;
};




1;
