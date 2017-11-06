package Krawfish::Corpus;
use strict;
use warnings;
use Krawfish::Util::Constants qw/NOMOREDOCS/;
use Role::Tiny;
use Krawfish::Log;

requires qw/current
            next
            next_doc
            skip_doc
            same_doc
            clone
            max_freq
            to_string
           /;

# Krawfish::Corpus is the base class for all corpus queries.

use constant DEBUG => 0;

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting->new(
    doc_id => $self->{doc_id},
    flags  => $self->{flags}
  );
};


# Overwrite query object
sub next_doc {
  return $_[0]->next;
};


# Overwrite
# Skip to (or beyond) a certain doc id.
# This should be overwritten to more effective methods.
sub skip_doc {
  my ($self, $target_doc_id) = @_;

  print_log('corpus', refaddr($self) . ': skip to doc id ' . $target_doc_id) if DEBUG;

  while (!$self->current || $self->current->doc_id < $target_doc_id) {
    $self->next_doc or return NOMOREDOCS;
  };

  return $self->current->doc_id;
};



# Move both operands to the same document
sub same_doc {
  my ($self, $second) = @_;

  my $first_c = $self->current or return;
  my $second_c = $second->current or return;

  # Iterate to the first matching document
  while ($first_c->doc_id != $second_c->doc_id) {
    print_log('corpus', 'Current span is not in docs') if DEBUG;

    # Forward the first span to advance to the document of the second span
    if ($first_c->doc_id < $second_c->doc_id) {
      print_log('corpus', 'Forward first') if DEBUG;
      if ($self->skip_doc($second_c->doc_id) == NOMOREDOCS) {
        return;
      };
      $first_c = $self->current;
    }

    # Forward the second span to advance to the document of the first span
    else {
      print_log('corpus', 'Forward second') if DEBUG;
      if ($second->skip_doc($first_c->doc_id) == NOMOREDOCS) {
        return;
      };
      $second_c = $second->current;
    };
  };

  return 1;
};


# Per default every operation is complex
sub complex {
  return 1;
};


1;
