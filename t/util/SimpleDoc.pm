use strict;
use warnings;

sub simple_doc {
  my @list = @_;

  my @tokens;
  foreach (@_) {
    push @tokens, {
      'key' => $_,
      '@type' => 'koral:token'
    }
  };

  return {
    doc => {
      annotation => \@tokens
    }
  };
};

1;
