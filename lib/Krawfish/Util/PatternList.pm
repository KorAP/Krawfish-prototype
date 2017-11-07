package Krawfish::Util::PatternList;
use Krawfish::Log;
use Data::Dumper;
use parent 'Exporter';
use strict;
use warnings;

# Based on a pattern, this creates a list.
#
# Expect a list of structure
#   [[0,1],[3,5,8],[2]]
#
# And creates a list like
#   0,3,2
#   0,5,2
#   0,8,2
#   1,3,2
#   1,5,2
#   1,8,2

# This is used by
# Krawfish::Koral::Result::Group::Fields

# TODO:
#   This should probably be relocated to
#   Krawfish::Koral::Util::*

our @EXPORT = qw/pattern_list/;

use constant DEBUG => 0;


sub pattern_list {
  my @list = @_;

  if (DEBUG) {
    print_log('util_plist', 'Pattern is ' . Dumper(\@list));
  };

  # Branch is initialized with
  # pointing at the final character
  my $branch = scalar(@list) -1;

  # The counter takes note on the current state
  my @counter = (0) x ($branch + 1);

  # List of results
  my @results;
  my $i;

  if (DEBUG) {
    print_log(
      'util_plist',
      'Initialize counter: [' . join(',',@counter) . '] ' .
        'with branch at ' . $branch);
  };

  # Iterate over all permutations
  while ($branch >= 0) {

    # Current result
    my @result = ();

    # Iterate over list
    for ($i = 0; $i < @list; $i++) {
      $result[$i] = $list[$i]->[
        $counter[$i]
      ];
    };

    if (DEBUG) {
      print_log('util_plist', 'Result is:  [' . join(',',@result) . ']');
      print_log('util_plist', 'Counter is: [' . join(',',@counter) . ']');
    };

    push @results, \@result;
    $branch = scalar(@list) -1;

    if (DEBUG) {
      print_log('util_plist', 'Check branchability at ' . $branch);
    };


    # Check if the options list is larger then the incremented counter
    while (++$counter[$branch] > @{$list[$branch]} - 1) {

      if (DEBUG) {
        print_log('util_plist', 'Not branchable at ' . $branch . ' anymore');
      };

      $branch--;

      if (DEBUG) {
        print_log('util_plist', 'Set branch test at ' . $branch);
      };

      last if $branch < 0;

      # Reset all following pointers
      for ($i = $branch + 1; $i <= scalar(@list) -1; $i++) {
        $counter[$i] = 0;

        if (DEBUG) {
          print_log('util_plist', 'Set counter at ' . $i . ' to 0');
        };
      };
    };

    last if $branch < 0;
  };


  return @results;
};


1;
