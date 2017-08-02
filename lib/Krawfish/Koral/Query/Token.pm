package Krawfish::Koral::Query::Token;
use parent 'Krawfish::Koral::Query';
# use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Term;
# use Krawfish::Query::Term;
use Krawfish::Log;
use strict;
use warnings;
use Scalar::Util qw/blessed/;

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
      operands => [Krawfish::Koral::Query::Term->new($token)]
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


# Overwrite is any
sub is_any {
  return if $_[0]->is_nothing;
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
    if ($op->is_nothing) {
      $self->operands([]);
      $self->is_nothing(1);
    }
    elsif ($op->is_any) {
      $self->operands([]);
      $self->is_any(1);
    }
    elsif (!$self->is_optional && !$self->is_negative) {
      return $op;
    }
    else {
      $self->operands([$op]);
    };
  };

  # No operand defined - ANY query
  return $self;
};


sub inflate {
  my ($self, $dict) = @_;
  print_log('kq_token', 'Inflate wrapper') if DEBUG;
  $self->operands([$self->operand->inflate($dict)]);
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
    $self->error(000, 'Unable to search for any tokens');
    return;
  };

  return $self;
};


sub optimize {
  my ($self, $index) = @_;

  # Create token query
  unless ($self->operand) {
    warn "It's not possible to optimize an any query";
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
  return $self->operand->optimize($index);
};



# Stringify
sub to_string {
  my $self = shift;

  my $string = '[';

  if ($self->is_nothing) {
    $string .= '0';
  }
  elsif ($self->is_any) {
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
    if ($wrap->{'@type'} eq 'koral:term') {
      return $class->new($importer->term($wrap));
    }
    elsif ($wrap->{'@type'} eq 'koral:termGroup') {
      return $class->new($importer->term_group($wrap));
    }
    else {
      warn 'Wrap type not supported!'
    };
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
