use strict;
use warnings;

sub simple_doc {
  my @list = @_;

  my @tokens;
  foreach (@_) {
    push @tokens, { 'key' => $_ }
  };

  return {
    doc => {
      annotation => \@tokens
    }
  };
};

1;
