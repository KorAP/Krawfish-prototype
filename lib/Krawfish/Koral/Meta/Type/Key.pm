package Krawfish::Koral::Meta::Type::Key;
use Krawfish::Koral::Meta::Type::KeyID;
use strict;
use warnings;
use Krawfish::Util::String qw/squote/;

sub new {
  my $class = shift;
  my $term = shift;
  bless \$term, $class;
};


# Identify key ids
sub identify {
  my ($self, $dict) = @_;

  # Get term from dictionary
  my $term_id = $dict->term_id_by_term('!' . $$self);

  # Term does not exist!
  return unless $term_id;

  # Return identifier
  Krawfish::Koral::Meta::Type::KeyID->new(
    $term_id
  );
};

sub to_string {
  squote(${$_[0]});
};

1;
