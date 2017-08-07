package Krawfish::Corpus::Cache;
use parent 'Krawfish::Corpus';
use Krawfish::Index::Stream;
use Krawfish::Cache;
use strict;
use warnings;

# Caching is not always a good thing. Caching is only applyable
# to certain subqueries, caching may slow down the queries, when the
# cache is not indexed, caching as for now has to be done on the
# index level only and caching will probably need an "invalidate all
# caches" mechanism whenever an index changes.
# See
#   http://mysqlserverteam.com/mysql-8-0-retiring-support-for-the-query-cache/
# for further opinions. But caching may be beneficial in our scenario
# for the use of virtual corpora, so we should definitely use it.
# Caches may also be implemented optimized (like with Roaring BitSets)
# to make them very effective.

# TODO:
#  There should probably be a multi-step analysis
#  for caching.
#  - Check complexity -> cache or cache_maybe
#  - If maybe caching, don't cache, but analyze the
#    the timing. If the query was time consuming with small results
#    marc the cache key as "cache next time"
#  - If a query is cached but not indexed, the cache may
#    be indexed next time
#  - the signature of the koralquery can be used for caching

# A cache may not necessarily be invalidated.
# It may be filtered using the live document vector (so it is
# not necessary to invalidate all caches on an updated)
# and it may be used for the length of the old vector
# (using and caching the query for all documents beyond).
# For that, caches may need to be extensible (new entries
# need to be appended).


# Return either a dynamic caching query or a cached stream
sub new {
  my $class = shift;
  my $self = bless {
    span => shift,
    cache => (shift // Krawfish::Cache->new),
    doc_id => undef
  }, $class;

  $self->{key} = $self->{span}->to_string;

  # Query is cached - return stream
  if (my $cache = $self->{cache}->get($self->{key})) {
    # return Krawfish::Stream::Doc->new($cache);
    # This would also support skip_doc()!
  };

  # Query is not cached
  # $self->{stream} = Krawfish::Stream:Doc->new;
  warn 'Caching not yet supported';
  return $self;
};


sub clone  {
  ...
};

sub next {
  my $self = shift;

  # If next is possible - move forward
  if ($self->{span}->next) {
    my $last_doc_id = $self->{doc_id};
    my $doc_id = $self->current->doc_id;

    # Add doc_id delta to stream
    # $self->{stream}->add_vint($doc_id - $last_doc_id);

    $self->{doc_id} = $doc_id;
    return 1;
  };

  # No more entries
  # Cache virtual corpus
  $self->{cache}->set($self->{key}, $self->{stream}->raw);
};


sub skip_doc {
  my ($self, $doc_id) = @_;

  # Is already at doc_id
  if ($self->{doc_id} == $doc_id) {
    return $doc_id;
  };

  # If next is possible - move forward
  while ($self->next) {
    return $self->{doc_id} if $doc_id >= $self->{doc_id};
  };

  return;
};


sub to_string {
  my $self = shift;
  return 'cache(' . $self->{span}->to_string . ')';
};

sub max_freq {
  $_[0]->{span}->max_freq;
};

1;
