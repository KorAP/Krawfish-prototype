package Krawfish::Meta::Group::Character;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    segments   => shift, # Krawfish::Index::Segments object
    # TODO: May as well be a subtoken object
    from_start => shift,  # boolean - otherwise from end
    char_count => shift
    nrs => [@_]
  }, $class;
};


sub get_group {
  my ($self, $match) = @_;

  # Get all classes from the match
  my @classes = $match->get_classes($self->{nrs});

  my $segments = $self->{segments};

  my %group;

  # Classes have nr, start, end
  foreach my $class (sort { $a->start <=> $b->start } @classes) {

    if ($self->{from_start}) {

      # This will retrieve the segment from the segments stream
      my $segment = $stream->get($match->doc_id, $class->start);

      if ($segment->)

        # The character count can be satisfied by the
      my $first_chars = $segment->first_chars;

      if (length($first_chars) <= $self->{char_count} {
        substr($first_chars);
      }
      
      # Check, if the segment only spans one segment
      if ($class->end != $class->start+1) {
        
      };
    }
    else {
      ...
    };
  };
};

1;
