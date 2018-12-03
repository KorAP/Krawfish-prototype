package Test::Krawfish::RepetitionPattern;
use warnings;
use strict;
use Test::More ();
use parent 'Test::Builder::Module';
our @EXPORT = qw(ok_repetition);


sub ok_repetition {
  my ($repp, $ok) = @_;
  my $desc = 'Test repetition pattern';

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $tb = Test::More->builder;

  my %ok = map { $_ => 1 } @$ok;

  foreach my $test (0..100) {
    my $result = $repp->check($test);

    # Requires true result
    if ($ok{$test}) {
      unless ($result) {
        return $tb->ok(0, $desc . ': ' . $test . ' doesn\'t match');
      };
    }
    elsif ($result) {
      return $tb->ok(0, $desc . ': ' . $test . ' matches') if $result;
    };
  };

  return $tb->ok(1, $desc);
};

1;
