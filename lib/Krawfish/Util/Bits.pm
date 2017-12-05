package Krawfish::Util::Bits;
use Krawfish::Log;
use parent 'Exporter';
use bytes;
use strict;
use warnings;

use constant DEBUG => 0;

our @EXPORT;

@EXPORT = qw/bitstring classes_to_flags flags_to_classes/;

# Return the bit string for 2 bytes
sub bitstring ($) {
  return unpack "b16", pack "s", shift;
};


# Create flags based on classes
sub classes_to_flags {
  my $flags = 0b0000_0000_0000_0000;

  foreach (@_) {
    $flags |= (1 << (15 - $_))
  };

  return $flags;
};


# Create classes based on flags
sub flags_to_classes ($) {
  my $flags = shift;

  return () if bitstring($flags) eq '0000'.'0000'.'0000'.'0000';

  # Initialize move variable
  my $move = 0b1000_0000_0000_0000;

  my $i = 0;
  my @list;

  # As long as there a set bits ...
  while ($flags) {

    if (DEBUG) {
      print_log(
        'post',
        'Check move ' . reverse(bitstring($move)) . ' and flags ' .
          reverse(bitstring($flags)) . " - $move|$flags"
      );
    };

    if ($flags & $move) {
      if (DEBUG) {
        print_log(
          'post',
          'Move ' . reverse(bitstring($move)) . ' matches ' . reverse(bitstring($flags))
        );
      };
      push @list, $i;
      $flags &= ~$move;
    };
    $move >>= 1;
    $i++;
  };

  # Return list of valid classes
  return @list;
};

1;
