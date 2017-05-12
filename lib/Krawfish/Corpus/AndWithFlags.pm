package Krawfish::Corpus::AndWithFlags;
use parent 'Krawfish::Corpus::And';
use Krawfish::Posting::DocWithFlags;
use Krawfish::Log;
use strict;
use warnings;

# "and with flags" queries are similar
# to "and" queries, but they respect flags
# and are therefore not cachable

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift,
    flags => 0b0000_0000_0000_0000
  }, $class;
};


sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting::DocWithFlags->new(
    $self->{doc_id},
    $self->{flags}
  );
};


sub next {
  ...;
};

1;
