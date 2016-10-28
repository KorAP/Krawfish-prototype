use strict;
use warnings;

# Convert: qw/aa bb aa bb/
sub simple_doc {
  my @list = @_;

  my @tokens;
  foreach (@_) {
    push @tokens, _token($_)
  };

  return {
    text => {
      annotation => \@tokens
    }
  };
};

# Convert:   '[aa][bb][aa][bb]'
#            '[aa|bb][bb][aa|bb][bb]'
#            '<1:xy>[aa]<2:z>[bb]</1>[cc]</2>'
sub complex_doc {
  my $string = shift;

  my @segments;
  my @tokens;
  my %spans;
  my $segment = 0;

  while ($string =~ /\G\s*(<[^>]+?>|\[[^\]]+?\])/g) {
    my $token = $1;

    # Found a token description
    if ($token =~ /^\[((?:[^\]\|]+?)\s*(?:\|\s*(?:[^\]\|]+?))*)\]$/) {
      my @token_in_group = split(/\s*\|\s*/, $1);

      # This is a token group
      if (@token_in_group > 1) {

        # Iterate over all elements of the group
        my @group;
        foreach (@token_in_group) {
          push @group, _token($_);
        };

        # Push group to token list
        push @tokens, _token_group(\@group, $segment);
      }

      # Only a single token available
      else {
        # Push token to token list
        push @tokens, _token($token_in_group[0], $segment);
      };

      $segment++;
    }

    # Found a span opening
    elsif ($token =~ /^<(\d)+:([^>]+?)>$/) {
      my $span = _span($2, $segment);

      # Remember span to modify
      $spans{$1} = $span;
      push @tokens, $span;
    }

    # Found a span closing
    elsif ($token =~ /^<\/(\d+?)>$/) {
      if (exists $spans{$1}) {
        my $seg = $segment -1;
        if ($seg != $spans{$1}->{segments}->[0]) {
          push @{$spans{$1}->{segments}}, $segment -1;
        };
      }
      else {
        warn "Span $1 unknown\n";
      };
    };
  };

  @tokens = sort _token_sort @tokens;

  return {
    text => {
      annotation => \@tokens
    }
  };
};

# Return token object
sub _token {
  my $hash = _key(shift);
  $hash->{'@type'} = 'koral:token';
  if (defined $_[0]) {
    $hash->{'segments'} = [@_];
  };
  return $hash;
};


# return tokenGroup object
sub _token_group {
  my $hash = {
    '@type' => 'koral:tokenGroup',
    'wrap' => shift
  };
  if (defined $_[0]) {
    $hash->{'segments'} = [@_];
  };
  return $hash;
};

sub _token_sort {
  return 0 unless $a->{segments} && $b->{segments};
  my $seg_a = $a->{segments};
  my $seg_b = $b->{segments};
  if ($seg_a->[0] < $seg_b->[0]) {
    return -1;
  }
  elsif ($seg_a->[0] > $seg_b->[0]) {
    return 1;
  }
  elsif ($seg_a->[-1] < $seg_b->[-1]) {
    return -1;
  }
  elsif ($seg_a->[-1] > $seg_b->[-1]) {
    return 1;
  };
  return 0;
};


# Return span object
sub _span {
  my $key = _key(shift);
  $key->{'@type'} = 'koral:span';
  $key->{'segments'} = [shift];
  return $key;
};


# Analyze key elements (foundry, layer, key)
sub _key {
  my $key = shift;
  if ($key =~ m!^([^\/]+?)(?:/([^=]))?=(.+)$!) {
    my $hash = {
      key => $3,
      foundry => $1
    };
    if ($2) {
      $hash->{layer} = $2;
    };
    return $hash;
  }
  else {
    return { key => $key };
  }
};

1;
