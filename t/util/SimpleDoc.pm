use strict;
use warnings;

# Currently: qw/aa bb aa bb/
# Better:    '[aa][bb][aa][bb]'
#            '[aa|bb][bb][aa|bb][bb]'
#            '<1:xy>[aa]<2:z>[bb]</1>[cc]</2>'
# Empty spaces should be irrelevant

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
