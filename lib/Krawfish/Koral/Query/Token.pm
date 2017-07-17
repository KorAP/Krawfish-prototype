package Krawfish::Koral::Query::Token;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Term;
use Krawfish::Log;
use strict;
use warnings;
use Scalar::Util qw/blessed/;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $token = shift;

  # Any token
  unless ($token) {
    return bless { wrap => undef }, $class;
  };

  # Token is a string
  unless (blessed $token) {
    return bless {
      wrap => Krawfish::Koral::Query::Term->new($token)
    }, $class;
  };

  # Token is already a group or a term
  bless {
    wrap => $token
  };
};

sub type { 'token' };

sub wrap {
  $_[0]->{wrap};
};

sub remove_classes {
  $_[0];
};

# Return Koral fragment
sub to_koral_fragment {
  my $self = shift;

  my $token = {
    '@type' => 'koral:token'
  };

  if ($self->wrap) {
    $token->{wrap} = $self->wrap->to_koral_fragment;
  };

  $token;
};


# Overwrite is any
sub is_any {
  return if $_[0]->is_nothing;
  return 1 unless $_[0]->wrap;
  return;
};


sub normalize {
  my $self = shift;
  print_log('kq_token', 'Normalize wrapper') if DEBUG;
  if ($self->wrap) {
    $self->{wrap} = $self->wrap->normalize;
    if ($self->{wrap}->is_nothing) {
      $self->{wrap} = undef;
      $self->is_nothing(1);
    }
    elsif ($self->{wrap}->is_any) {
      $self->{wrap} = undef;
      $self->is_any(1);
    }
    elsif (!$self->is_optional && !$self->is_negative) {
      return $self->{wrap};
    };
  };
  return $self;
};


sub inflate {
  my ($self, $dict) = @_;
  print_log('kq_token', 'Inflate wrapper') if DEBUG;
  $self->{wrap} = $self->wrap->inflate($dict);
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
  unless ($self->wrap) {
    $self->error(000, 'Unable to search for any tokens');
    return;
  };

  return $self;
};


sub optimize {
  my ($self, $index) = @_;

  # Create token query
  unless ($self->wrap) {
    warn "It's not possible to optimize an any query";
    return;
  };

  if ($self->wrap->type eq 'term') {
    return Krawfish::Query::Term->new(
      $index,
      $self->wrap->to_string
    );
  };

  print_log('kq_token', 'Optimize and return wrap token') if DEBUG;
  return $self->wrap->optimize($index);
};


# Query planning
sub plan_for {
  my ($self, $index) = @_;

  warn 'DEPRECATED';

  # Token is null
  if ($self->is_null) {
    $self->error(000, 'Unable to search for null tokens');
    return;
  };

  # No term defined
  unless ($self->wrap) {
    $self->error(000, 'Unable to search for any tokens');
    return;
  };

  # Create token query
  if ($self->wrap->type eq 'term') {
    return Krawfish::Query::Term->new(
      $index,
      $self->wrap->to_string
    );
  };

  return $self->wrap->plan_for($index);
};



# Filter by corpus
sub filter_by {
  ...
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
  elsif ($self->wrap) {
    if ($self->is_negative) {
      $string .= '!';
    };

    $string .= $self->wrap->to_string;
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

1;
