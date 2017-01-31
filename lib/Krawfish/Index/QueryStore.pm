package Krawfish::Index::QueryStore;
use Krawfish::Log;
use Krawfish::Cache;
use strict;
use warnings;

# TODO:
#   This is just an idea how to replace/reference
#   subqueries for optimization
#  - The reference store is used to check, if subqueries
#    are used elsewhere in the query and can be replaced
#    by references
#  - The cache store is used to check, if subqueries
#    are already processed and can directly be retrieved
#    from cached instead of postingslists
#  - If a subquery is not in cache but may potentially
#    be cached (for example a reference query to a
#    virtual corpus), the subquery can be wrapped in a
#    cached query

sub new {
  my $class = shift;
  bless {
    # TODO: Use a real cache!
    refs => {},
    refs_used => {},
    cache => Krawfish::Cache->new,
    cache_potential => {}
  }, $class;
};


# Check all subqueries and replace them
sub check_subqueries {
  my ($self, $query) = @_;

  # Iterate over all subqueries
  $query->replace_subqueries(
    sub {
      my $sub_query = shift;

      # Ignore posting list queries
      return if $sub_query->type =~ m/term|span/;

      # Get the signature
      my $sig = $sub_query->signature;

      # Mark this signature as probably useful for caching
      # This may based on $sub_query->complexity
      $self->{cache_potential}->{$sig}++;

      # The cache is already given
      if (my $cache = $self->{cache}->get($sig)) {

        # Return cache
        return $cache;
      }

      # The reference is already given
      elsif (exists $self->{refs}->{$sig}) {

        # This needs to be lifted as well
        $self->{refs_used}->{$sig} = 1;

        # Return reference
        return Krawfish::Koral::Query::Reference->new($sig);
      };

      # Mark this ref as used
      $self->{refs}->{$sig} = $sub_query;

      # Check subquery
      $self->check_subqueries($sub_query);

      # TODO: This is arbitrary!
      if ($self->{cache_potential} > 100) {

        # Return with a cache query
        return Krawfish::Query::Cache->new($sub_query);
      };

      # Do nothing
      return;
    }
  };
};
