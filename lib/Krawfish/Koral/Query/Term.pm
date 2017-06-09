package Krawfish::Koral::Query::Term;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Term;
use Krawfish::Query::Filter;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;

# TODO: Support escaping! Especially for regex!
# TODO: Filter multiple corpora

# TODO: Term building should be part of
#   a utility class Krawfish::Util::Koral::Term or so

use constant DEBUG => 1;

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

sub is_leaf { 1 };

sub is_nothing { 0 };

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

    $self->[4] = $match;
    return $self;
  };
  $self->[4] // '=';
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


sub filter_by {
  if ($_[1]) {
    $_[0]->[7] = $_[1];
    return $_[0];
  };
  $_[0]->[7];
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

  if ($self->match eq '!=') {
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

  return 0 if $self->is_null;

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


sub to_term {
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

  # There is a filter - normalize
  if ($self->filter_by) {

    # Normalize filter
    my $filter = $self->filter_by($self->filter_by->normalize);

    # Filter is nothing
    return $self->builder->nothing if $filter->is_nothing;
  };

  # return $self->is_negative || $self->is_null;
  return $self;
};



sub inflate {
  my ($self, $dict) = @_;

  # There is a filter - normalize
  if ($self->filter_by) {

    # Normalize filter
    my $filter = $self->filter_by($self->filter_by->inflate($dict));

    # Filter is nothing
    return $self->builder->nothing if $filter->is_nothing;
  };

  # Do not inflate
  return $self unless $self->is_regex;

  # Get terms
  my $term = $self->to_term_escaped;

  # Get terms from dictionary
  my @terms = $dict->terms(qr/^$term$/);

  if (DEBUG) {
    print_log('regex', 'Expand /^' . $term . '$/');
    print_log('regex', 'to ' . substr(join(',', @terms), 0, 50));
  };

  return $self->builder->nothing unless @terms;

  # TODO:
  #   Use refer?
  return $self->builder->term_or(@terms)->normalize;
};



sub optimize {
  my ($self, $index) = @_;

  # TODO:
  #   I don't know if this is fine here

  # Term is filtered
  if ($self->filter_by) {

    print_log('kq_term', 'Apply the term filter on ' . $self->filter_by->to_string) if DEBUG;

    my $filter = $self->filter_by->optimize($index);

    print_log('kq_term', 'Filter serialization is ' . $filter->to_string) if DEBUG;

    # Filter is empty
    return $self->builder->nothing if $filter->freq == 0;

    return Krawfish::Query::Filter->new(
      Krawfish::Query::Term->new($index, $self->to_term),
      $filter
    );
  };

  return Krawfish::Query::Term->new($index, $self->to_term);
};



sub plan_for {
  my $self = shift;
  my $index = shift;

  return if $self->is_negative || $self->is_null;

  # Expand regular expressions
  if ($self->is_regex) {

    # Get terms
    my $term = $self->to_term_escaped;
    my @terms = $index->dict->terms(qr/^$term$/);

    if (DEBUG) {
      print_log('regex', 'Expand /^' . $term . '$/');
      print_log('regex', 'to ' . substr(join(',', @terms), 0, 50));
    };

    return $self->builder->nothing unless @terms;

    my $builder = $self->builder;

    my $or;

    # Regex is filtered
    if ($self->filter_by) {
      $or = $builder->term_or(@terms)->filter_by($self->filter_by)->plan_for($index);
    }
    else {
      $or = $builder->term_or(@terms)->plan_for($index);
    };
    return $or;
  };

  # Term is filtered
  if ($self->filter_by) {

    print_log('kq_term', 'Apply the term filter on ' . $self->filter_by->to_string) if DEBUG;

    my $filter = $self->filter_by->plan_for($index);

    print_log('kq_term', 'Filter serialization is ' . $filter->to_string) if DEBUG;

    # Filter is empty
    return $self->builder->nothing if $filter->freq == 0;

    return Krawfish::Query::Filter->new(
      Krawfish::Query::Term->new($index, $self->to_term),
      $filter
    );
  };

  return Krawfish::Query::Term->new($index, $self->to_term);
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
  $term->match('' . $kq->{match}) if $kq->{match};

  # TODO: Support deserialization of regex!
  return $term;
};

1;
