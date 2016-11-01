package Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Corpus::Field;
use Krawfish::Koral::Corpus::Group;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless \(my $self = ''), $class;
};

# Create 'and' group
sub and {
  shift;
  return Krawfish::Koral::Corpus::Group->new('and', @_);
};

# Create 'or' group
sub or {
  shift;
  return Krawfish::Koral::Corpus::Group->new('or', @_);
};

# Create 'string' field
sub string {
  shift;
  return Krawfish::Koral::Corpus::Field->new('string', @_);
};

# Create 'date' field
sub date {
  shift;
  return Krawfish::Koral::Corpus::Field->new('date', @_);
};

# Create 'integer' field
sub regex {
  shift;
  return Krawfish::Koral::Corpus::Field->new('regex', @_);
};

1;

__END__
