package Krawfish::Search::FieldSort;
use strict;
use warnings;

# Todo: This is just an experiment!

sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    sort_by => [@_]
  }, $class;

  my $self = shift;
  my $query = $self->{query};

  my $index = $self->{index};

  # Fields
  my $fields = $index->fields;

  # TODO: This should be a linked list!
  my @sorted_result;
  my @equally_ranked;

  for (my $i = 0; $i <= @{$self->{sort_by}}; $i++) {
    my $sort_by = $self->{sort_by};

    # Get the rank of the field
    # This should probably be an object instead of an array
    my $rank = $fields->docs_ranked($sort_by[$i]);

    if ($i == 0) {
      while ($query->next) {
        my $doc_id = $self->current->doc_id;
        my $doc_rank = $rank->[$doc_id];

        # TODO: This should be added sorted
        my $pos = 4; # is a pointer to the first identical element in the list
        push @sorted, [@sorted_result, $doc_rank];

        # There are identical occurrences ...
        if ($sorted[$pos + 1] eq $sorted[$pos]) {

          # TODO: Only mark the first identical occurrence
          push @equally_ranked, $pos;
        };
      };
    }
    elsif (@sorted_equally) {
      ...
    };
  };

  return $self;
};

# Iterated through the ordered linked list
sub next {
  ...
};

1;
