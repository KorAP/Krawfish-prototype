package Krawfish::Koral::Query::Or;
use parent ('Krawfish::Koral::Util::Boolean','Krawfish::Koral::Query');
use Krawfish::Log;
use Krawfish::Query::Or;
use strict;
use warnings;

# Or-Construct on spans

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    operands => [@_]
  }
};

sub type {
  'or'
};

sub operation {
  'or'
};

sub bool_or_query {
  my $self = shift;
  Krawfish::Query::Or->new(
    $_[0],
    $_[1]
  );
};


# Can't occur per definition
sub bool_and_query {
  return;
};

# Stringification
sub to_string {
  my $self = shift;
  return join '|', map { '(' . $_->to_string . ')'} @{$self->operands_in_order};
};


1;
