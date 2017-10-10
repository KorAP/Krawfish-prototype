package Krawfish::Index::Forward::Doc;
use Krawfish::Log;
use warnings;
use strict;

use constant DEBUG => 0;


# TODO:
#   The forward index may need to contain casefolded terms as well,
#   so grouping on terms can support casefolding.



sub new {
  my $class = shift;
  my $doc = shift;

  my @data;

  # Point to previous subtoken (should be xor)
  push @data, 0;

  my $start_marker;

  # Add annotation data
  my $stream = $doc->stream;
  foreach my $subtoken (@$stream) {

    # Point to next subtoken (should be xor)
    push @data, '?';
    $start_marker = $#data;

    push @data, $subtoken->term_id;
    push @data, $subtoken->preceding;

    my @sorted_annotations = sort {
      if ($a->foundry_id < $b->foundry_id) {
        -1;
      }
      elsif ($a->foundry_id > $b->foundry_id) {
        1;
      }
      elsif ($a->layer_id < $b->layer_id) {
        -1;
      }
      elsif ($a->layer_id > $b->layer_id) {
        1;
      }
      elsif ($a->term_id < $b->term_id) {
        -1;
      }
      elsif ($a->term_id > $b->term_id) {
        1;
      }
      else {
        0;
      };
    } @{$subtoken->annotations};

    # Add all annotations to the stream
    foreach (@sorted_annotations) {
      push @data, $_->foundry_id;
      push @data, $_->layer_id;
      push @data, $_->type;
      push @data, $_->term_id;
      push @data, [@{$_->data}];
    };

    push @data, 'EOA';

    push @data, $start_marker -1;         # Point to previous subtoken
    if (DEBUG) {
      print_log('fwd_doc', "Set start marker at $start_marker from " .
                  $data[$start_marker] . " to " . $#data);
    };
    $data[$start_marker] = $#data;     # Update last subtoken

    if (DEBUG) {
      print_log(
        'fwd_doc',
        'Subtoken is ' .
          join(
            ',',
            map { defined $_ ? $_ : '?' }
              @data[$start_marker - 1 .. $#data -1]
            )
        );
    };
  };

  push @data, 'EOF';

  bless \@data, $class;
};


sub to_string {
  my $self = shift;
  my ($offset, $length) = @_;
  $offset //= 0;
  $length //= $offset+10;
  return join(',', map {
    '[' . (defined $_ ? $_ : '?') . ']'
  } @{$self}[$offset .. $length]);
};



1;
