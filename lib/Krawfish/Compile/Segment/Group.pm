package Krawfish::Compile::Segment::Group;
use parent 'Krawfish::Compile';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# Override to compile data
sub compile {
  my $self = shift;

  if (DEBUG) {
    print_log('c_group', 'Compile group');
  };

  # Get result object
  my $result = $self->result;

  # Add all results
  while ($self->next) {
    if (DEBUG) {
      print_log(
        'compile',
        'Check match ' . $self->current->to_string
      );
    };
  };

  # Set group to result
  $result->group(
    $self->group
  );

  # Collect more data
  my $query = $self->{query};
  if ($query->isa('Krawfish::Compile')) {
    $query->result($result)->compile;
  };

  if (DEBUG) {
    print_log(
      'compile',
      'Result is ' . $result
    );
  };
  return $result;
};



# Get collection
sub collection {
  warn 'DEPRECATED';
  $_[0]->{result};
};


# Get collection
sub group {
  $_[0]->{group};
};


# Get collection
# sub result {
#   $_[0]->{result};
# };


# Get current posting
sub current {
  return $_[0]->{query}->current;
};

1;
