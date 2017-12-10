package Krawfish::Koral::Query::Token;
use Role::Tiny::With;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use strict;
use warnings;
use Scalar::Util qw/blessed/;

with 'Krawfish::Koral::Query';

use constant DEBUG => 0;

# Token based query containing boolean definition of terms.

# TODO:
#   Token should probably introduce a unique-query to filter out multiple matches.
#   It should also remove classes, that are not allowed.

sub new {
  my $class = shift;
  my $token = shift;

  # Any token
  unless ($token) {
    return bless { operands => [] }, $class;
  };

  # Token is a string
  unless (blessed $token) {
    return bless {
      operands => [Krawfish::Koral::Query::Term->new(TOKEN_PREF . $token)]
    }, $class;
  };

  # Token is already a group or a term

  # TODO:
  #   Check that everything else is invalid!
  bless {
    operands => [$token]
  };
};


# Query type
sub type { 'token' };


# There are no classes allowed in tokens
sub remove_classes {
  $_[0];
};


# Overwrite is anywhere
sub is_anywhere {
  return if $_[0]->is_nowhere;
  return 1 unless $_[0]->operand;
  return;
};


# A token always spans exactly one token
sub min_span {
  return 0 if $_[0]->is_null;
  1;
};


# A token always spans exactly one token
sub max_span {
  return 0 if $_[0]->is_null;
  1;
};


# Normalize the token
sub normalize {
  my $self = shift;
  my $op;

  print_log('kq_token', 'Normalize wrapper') if DEBUG;

  # There is an operand defined
  if ($self->operand) {
    my $op = $self->operand->normalize;
    if ($op->is_nowhere) {
      $self->operands([]);
      $self->is_nowhere(1);
    }
    elsif ($op->is_anywhere) {
      $self->operands([]);
      $self->is_anywhere(1);
    }
    elsif (!$self->is_optional && !$self->is_negative) {
      return $op;
    }
    else {
      $self->operands([$op]);
    };
  };

  # No operand defined - ANYWHERE query
  return $self;
};


sub finalize {
  my $self = shift;

  # Token is null
  if ($self->is_null) {
    $self->error(000, 'Unable to search for null tokens');
    return;
  };

  # No term defined
  unless ($self->operand) {
    $self->error(000, 'Unable to search for anywhere tokens');
    return;
  };

  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  # Create token query
  unless ($self->operand) {
    warn "It's not possible to optimize an anywhere query";
    return;
  };

  # The operand is a single term - ignore the wrapping token
  # However - this would ignore the unique constraint for cases,
  # where terms are identical, but have different payload information
  #if ($self->operand->type eq 'term') {
  #  return Krawfish::Query::Term->new(
  #    $index,
  #    $self->operand->to_string
  #  );
  #};

  print_log('kq_token', 'Optimize and return wrap token') if DEBUG;
  return $self->operand->optimize($segment);
};



# Stringify
sub to_string {
  my ($self, $id) = @_;

  my $string = '[';

  if ($self->is_nowhere) {
    $string .= '0';
  }
  elsif ($self->is_anywhere) {
    $string .= '';
  }
  elsif ($self->operand) {
    if ($self->is_negative) {
      $string .= '!';
    };

    $string .= $self->operand->to_string;
  }

  $string .= ']';

  if ($self->is_null) {
    $string .= '{0}';
  }

  elsif ($self->is_optional) {
    $string .= '?';
  };

  return $string;
};


sub maybe_unsorted { 0 };

sub from_koral {
  my $class = shift;
  my $kq = shift;
  my $importer = $class->importer;

  # No wrap
  unless ($kq->{'wrap'}) {
    return $class->new;
  }

  # Wrap is a term
  else {
    my $wrap = $kq->{wrap};
    return $class->new(
      $importer->from_term_or_term_group($kq->{wrap})
    );
  }
};

# Return Koral fragment
sub to_koral_fragment {
  my $self = shift;

  my $token = {
    '@type' => 'koral:token'
  };

  if ($self->operand) {
    $token->{wrap} = $self->operand->to_koral_fragment;
  };

  $token;
};


1;
