package Krawfish::Compile::Segment::Group;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment';

requires qw/group/;

use constant DEBUG => 0;


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
  if (Role::Tiny::does_role($query, 'Krawfish::Compile::Segment')) {
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


# Get group
# TODO:
#   rename to group_result
sub group {
  $_[0]->{group};
};


# Get current posting
sub current {
  return $_[0]->{query}->current;
};

1;
