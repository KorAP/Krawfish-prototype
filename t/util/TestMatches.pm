use Test::More;

sub test_matches {
  my $query = shift;
  my @matches = @_;

  # Iterate over matches
  foreach (@_) {
    ok($query->next, 'Next for ' . $_);
    is($query->current->to_string, $_, 'Match for '.$_);
  };

  ok(!$query->next, 'No more matches');
};

1;
