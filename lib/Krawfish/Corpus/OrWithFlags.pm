package Krawfish::Corpus::OrWithFlags;
use parent 'Krawfish::Corpus::Or';
use Krawfish::Posting::DocWithFlags;
use Krawfish::Log;
use strict;
use warnings;

# "or with classes" queries are similar
# to "or" queries, but they respect flags
# and are therefore not cachable

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift,
    first_current => undef,
    second_current => undef,
    doc_id => -1,
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

__END__


sub next {
  $self = shift;
  $self->init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  print_log('vc_or_flags', 'Check postings') if DEBUG;

  # First doc matches
  $self->{flags} |= $first->flags if $first;

  # Second doc matches
  $self->{flags} |= $second->flags if $second;
};


{
  # Iterate to positions
  while ($first || $second) {

    # First span is no longer available
    if (!$first) {
      $curr = 'second';
    }

    # Second span is no longer available
    elsif (!$second) {
      print_log('vc_or_flags', 'Current is first operand (b)') if DEBUG;
      $curr = 'first';
    }

    elsif ($first->doc_id < $second->doc_id) {
      print_log('vc_or_flags', 'Current is first operand (1)') if DEBUG;
      $curr = 'first';
    }
    elsif ($first->doc_id > $second->doc_id) {
      print_log('vc_or_flags', 'Current is second operand (1)') if DEBUG;
      $curr = 'second';
    }
    else {
      print_log('vc_or_flags', 'Current is first operand (4)') if DEBUG;
      $curr = 'first';
    };

    # Get the current posting of the respective operand
    my $curr_post = $self->{$curr}->current;

    # Only return unique identifier
    if ($self->{doc_id} == $curr_post->doc_id) {

      if (DEBUG) {
        print_log('vc_or_flags', 'Document ID already returned: '. $self->{doc_id});
      };

      # Forward
      $self->{$curr}->next;

      # Set current docs
      $first = $self->{first}->current;
      $second = $self->{second}->current;

      next;
    };

    $self->{doc_id} = $curr_post->doc_id;

    if (DEBUG) {
      print_log('vc_or_flags', 'Current doc is ' . $self->current->to_string);
      print_log('vc_or_flags', "Next on $curr operand");
    };

    $self->{$curr}->next;
    return 1;
  };

  $self->{doc_id} = undef;
  return;
  };
};

1;
