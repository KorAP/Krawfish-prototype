package Krawfish::Koral::Query::Term;
use Role::Tiny::With;
use Krawfish::Util::Constants qw/:PREFIX/;
use Scalar::Util qw/looks_like_number/;
use Krawfish::Query::Term;
use Krawfish::Query::Nowhere;
use Krawfish::Log;
use strict;
use warnings;

with 'Krawfish::Koral::Query';
with 'Krawfish::Koral::Result::Inflatable';

# TODO:
#  Probably introduce '#' as a prefix for
#  token annotations!

# TODO: Support escaping! Especially for regex!

# TODO: Term building should be part of
#   a utility class Krawfish::Util::Koral::Term or so

# TODO:
#   Field is probably useless

# TODO:
#   The regex is valid for the value in case it is given.
#   Otherwise it's valid for the key.

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $term = shift;

  my %self;

  if ($term) {

    # Is term id!
    if (looks_like_number($term)) {
      $self{term_id} = $term;
    }

    elsif ($term =~ m!^(?:([^:\/]+?):)?   # 1 Field
                      ($ANNO_PREFIX_RE)?  # 2 Prefix
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

sub is_nowhere {
  0
};

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
  # TODO:
  #   Probably deal with span/relation types specially
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
  $_[0]->{prefix} // TOKEN_PREF;
};


sub term_type {
  my $self = shift;
  if ($_[0]) {
    if ($_[0] eq 'span') {
      $self->prefix(SPAN_PREF);
    }
    elsif ($_[0] eq 'attribute') {
      $self->prefix(ATTR_PREF);
    }
    elsif ($_[0] eq 'relation') {

      # Todo: This doesn't respect
      # direction
      $self->prefix(REL_L_PREF);
    }
    elsif ($_[0] eq 'token') {

      # Todo: This doesn't respect
      # direction
      $self->prefix(TOKEN_PREF);
    };
    return $self;
  }
  else {
    return 'token'     if $self->prefix eq TOKEN_PREF;
    return 'span'      if $self->prefix eq SPAN_PREF;
    return 'attribute' if $self->prefix eq ATTR_PREF;
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


sub term_id {
  $_[0]->{term_id};
};

# Create koral fragment
sub to_koral_fragment {
  my $self = shift;

  if ($self->{term_id}) {
    return {
      '@type' => 'koral:term',
      '@id' => 'term:' . $self->term_id
    };
  };

  # TODO:
  #   Respect term_type!
  my $hash = {
    '@type' => 'koral:term',
  };

  return $hash if $self->is_null;
  $hash->{key} = $self->key;
  $hash->{foundry} = $self->foundry if $self->foundry;
  $hash->{layer} = $self->layer if $self->layer;
  $hash->{value} = $self->value if $self->value;

  $hash->{type} = $self->is_regex ? 'type:regex' : 'type:string';

  if ($self->operator eq '!=') {
    $hash->{match} = 'match:ne';
  };

  return $hash;
};


# TODO:
#   Support fragment, where a term string
#   may end with / or = to be used for
#   suggestions


# stringify term
sub to_string {
  my ($self, $id) = @_;

  return '-' if $self->is_null;

  if (($id && $self->{term_id})
        ||
        (!$self->key && $self->{term_id})) {
    return '#' . $self->{term_id};
  };

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
  my $self = shift;
  return if $self->is_null;

  my $str = $self->field // '';
  if ($str) {
    $str .= ':';
  };
  $str .= $self->prefix;
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


sub to_neutral_escaped {
  my $self = shift;
  my $term = $self->to_neutral;
  # (?:[^:]+?\:)?
  if ($term =~ m!^(.(?:[^/]+?\/)?(?:[^=]+?)\=)(.+?)$!) {
    return quotemeta($1). $2;
  };
  return $term;
};


# Normalize term query
sub normalize {
  if (DEBUG) {
    print_log('kq_term', 'Normalize "' . $_[0]->to_string . '"');
  };
  $_[0];
  # return $self->is_negative || $self->is_null;
};


# Translate all terms to term_ids
sub identify {
  my ($self, $dict) = @_;

  # Is already a term id
  return $self if defined $self->{term_id};

  # Term is no regular expression
  unless ($self->is_regex) {

    my $term = $self->to_neutral;

    print_log('kq_term', "Translate term $term to term_id") if DEBUG;

    my $term_id = $dict->term_id_by_term($term);

    return $self->builder->nowhere unless defined $term_id;

    $self->{term_id} = $term_id;

    return $self;
    # return Krawfish::Koral::Query::Term->new($term_id);
  };

  # Get terms
  my $term = $self->to_neutral_escaped;

  print_log('kq_term', 'Inflate /^' . $term . '$/') if DEBUG;

  # Get term_ids from dictionary
  my @term_ids = $dict->term_ids(qr/^$term$/);

  if (DEBUG) {
    print_log(
      'kq_term',
      'Expand /^' . $term . '$/',
      'to ' . (@term_ids > 0 ? substr(join(',', map { '#' . $_ } @term_ids), 0, 50) : '[0]')
    );
  };

  # Build empty term instead of nowhere
  return $self->builder->nowhere unless @term_ids;

  # TODO:
  #   Use refer?
  my $or = $self->builder->bool_or(
    map {
      __PACKAGE__->new($_)
      } @term_ids
    );

  if (DEBUG) {
    print_log('kq_term', 'New boolean query is ' . $or . ': ' . $or->to_string(1));
  };

  return $or->normalize;
};


sub inflate {
  ...
};


sub optimize {
  my ($self, $segment) = @_;
  warn 'Identify before!' unless defined $self->term_id;
  return Krawfish::Query::Term->new($segment, $self->term_id);
};


sub is_anywhere {
  0;
};

sub is_optional {
  0
};


# Term is null
sub is_null {
  return 1 unless $_[0]->key || $_[0]->term_id;
  return;
};


sub is_negative {
  my $self = shift;

  return 0 if defined $self->term_id;

  if (scalar @_ == 1) {
    my $neg = shift;

    if ($neg && $self->match eq '=') {
      $self->match('!=');
    }
    elsif (!$neg && $self->match eq '!=') {
      $self->match('=');
    };
    return $self;
  };
  $self->match eq '!=' ? 1 : 0;
};



sub is_extended { 0 };
sub is_extended_right { 0 };
sub is_extended_left { 0 };
sub maybe_unsorted { 0 };
sub uses_classes {
  undef;
};

sub from_koral {
  my ($class, $kq) = @_;
  my $term = $class->new;

  if (my $id = $kq->{'@id'}) {
    $id =~ s/^term://;
    return $class->new($id);
  };

  $term->foundry('' . $kq->{foundry}) if $kq->{foundry};
  $term->layer('' . $kq->{layer}) if $kq->{layer};
  $term->key('' . $kq->{key}) if $kq->{key};
  $term->value('' . $kq->{value}) if $kq->{value};
  $term->match('' . $kq->{match}) if $kq->{match};

  # TODO: Support deserialization of regex!
  return $term;
};




1;
