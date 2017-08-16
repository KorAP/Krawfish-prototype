package Test::Krawfish;
use Krawfish::Log;
use Krawfish::Koral::Document;
use parent 'Test::Builder::Module';
use warnings;
use strict;
use Test::More ();
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile rel2abs splitdir/;
our @EXPORT = qw(test_doc test_file ok_index ok_index_2 matches);

use constant DEBUG => 0;

sub test_file {
  my @file = @_;
  my ($x, $fn) = caller();
  my @caller_dir = splitdir(rel2abs(dirname($fn)));
  my $i = 3;

  # Remove path till 't'
  while ($caller_dir[-1] ne 't') {
    pop @caller_dir;
    return if $i-- < 0;
  };

  return catfile(@caller_dir, 'data', @file);
};


sub test_doc {
  my $kq = {};
  my $doc = ($kq->{document} = {});

  if (ref $_[0] eq 'HASH') {
    $doc->{fields} = _fields(shift);
  };


  my ($pd, $anno, $subtokens);

  if (ref $_[0] eq 'ARRAY') {
    ($pd, $anno, $subtokens) = _simple_anno(shift);
  }
  else {
    ($pd, $anno, $subtokens) = _complex_anno(shift);
  };

  $doc->{annotations} = $anno if $anno;
  $doc->{primaryData} = $pd if $pd;
  $doc->{subtokens} = $subtokens if $subtokens;

  return $kq;
};

sub ok_index {
  my $index = shift;

  warn 'This is deprecated!';

  # This is in fact deprecated!
  my $meta;
  my $kq = test_doc(@_);

  my $desc = 'Add example document';

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $tb = Test::More->builder;
  $tb->ok(defined $index->add($kq), $desc);
};


sub ok_index_2 {
  my $index = shift;

  # This is in fact deprecated!
  my $meta;
  my $kq = test_doc(@_);

  # Get Koral document
  $kq = Krawfish::Koral::Document->new($kq);

  # Transform to term_ids
  $kq = $kq->identify($index->dict);

  my $desc = 'Add example document';

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $tb = Test::More->builder;

  # Add to segment
  $tb->ok(defined $index->segment->add($kq), $desc);
};


sub matches {
  my ($query, $matches, $desc) = @_;
  my $tb = Test::More->builder;

  $desc //= 'Test match';
  $desc .= ' ';

  # Iterate over matches
  foreach (@$matches) {
    unless ($query->next) {
      $tb->ok(0, $desc . '- next before ' . $_);
      return;
    };
    unless ($query->current->to_string eq $_) {
      $tb->ok(0,
        $desc . '- mismatch of ' . $query->current->to_string . ' vs. ' . $_
      );
      return;
    }
  };

  if ($query->next) {
    $tb->ok(0, $desc . '- more matches available, e.g. ' . $query->current->to_string);
  };

  $tb->ok($desc);
};


# Simple annotations
sub _simple_anno {
  my @tokens;
  my $primary_data = join ' ', @{$_[0]};

  print_log('test', "Primary data is '$primary_data'") if DEBUG;

  my @offsets = ();
  my $offset = 0;
  foreach (@{$_[0]}) {
    push @tokens, _token(_key($_));
    my $end = $offset + length($_);
    push @offsets, [$offset, $end];
    $offset = $end + 1;
  };

  if (DEBUG) {
    print_log(
      'test',
      'Offsets are ' . join(',', map { $_->[0] . '-' . $_->[1] } @offsets)
    );
  };

  return $primary_data, \@tokens, _subtokens(\@offsets)
};


# Complex annotations
sub _complex_anno {
  my $string = shift;

  my @subtokens;
  my @tokens;
  my %spans;

  # Subtoken data
  my $subtoken = 0;
  my $offset = 0;
  my (@primary_data, @offsets) = ();

  while ($string =~ /\G\s*(<[^>]+?>|\[[^\]]+?\])/g) {
    my $token = $1;

    # Found a token description
    if ($token =~ /^\[((?:[^\]\|]+?)\s*(?:\|\s*(?:[^\]\|]+?))*)\]$/) {
      my @split = split(/\s*\|\s*/, $1);
      my @group = map { _key($_) } @split;

      # This is a token group
      if (@group > 1) {

        # Push group to token list
        push @tokens, _token(\@group, $subtoken);
      }

      # Only a single token available
      else {
        # Push token to token list
        push @tokens, _token($group[0], $subtoken);
      };

      # Use first token for primary data;
      push @primary_data, $split[0];
      my $end = $offset + length($split[0]);
      push @offsets, [$offset, $end];
      $offset = $end + 1;
      $subtoken++;
    }

    # Found a span opening
    elsif ($token =~ /^<(\d)+:([^>]+?)>$/) {
      my $span = _span($2, $subtoken);

      # Remember span to modify
      $spans{$1} = $span;
      push @tokens, $span;
    }

    # Found a span closing
    elsif ($token =~ /^<\/(\d+?)>$/) {
      if (exists $spans{$1}) {
        my $seg = $subtoken -1;
        if ($seg != $spans{$1}->{subtokens}->[0]) {
          push @{$spans{$1}->{subtokens}}, $subtoken -1;
        };
      }
      else {
        warn "Span $1 unknown\n";
      };
    };
  };

  @tokens = sort _token_sort @tokens;
  my $primary_data = join(' ', @primary_data);

  return $primary_data, \@tokens, _subtokens(\@offsets);
};


# Return token object
sub _token {
  my $tokens = shift;
  my $hash = {
    '@type' => 'koral:token'
  };
  if (defined $_[0]) {
    $hash->{'subtokens'} = [@_];
  };

  if (ref $tokens eq 'ARRAY') {
    $hash->{wrap} = {
      '@type' => 'koral:termGroup',
      'operands' => $tokens
    }
  }
  else {
    $hash->{wrap} = $tokens
  };
  return $hash;
};

sub _fields {
  my $hash = shift;
  my @fields = ();
  foreach my $key (sort keys %$hash) {
    my $type = 'string';
    my $long_key = $key;
    if ($key =~ s/^(string|integer)_//) {
      $type = $1;
    };

    push(@fields, {
      '@type' => 'koral:field',
      'key' => $key,
      'value' => $hash->{$long_key},
      'type' => 'type:' . $type
    });
  };
  \@fields;
};

sub _subtokens {
  my $offsets = shift;
  my @subtokens = ();
  foreach (@$offsets) {
    push @subtokens, {
      '@type' => 'koral:subtoken',
      'offsets' => $_
    };
  };
  return \@subtokens;
};

sub _token_sort {
  return 0 unless $a->{subtokens} && $b->{subtokens};
  my $seg_a = $a->{subtokens};
  my $seg_b = $b->{subtokens};
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
  my $key = {
    '@type' => 'koral:span',
    'wrap' => _key(shift)
  };
  $key->{'subtokens'} = [shift];
  return $key;
};


# Analyze key elements (foundry, layer, key)
sub _key {
  my $key = shift;
  my $hash = {
    '@type' => 'koral:term'
  };
  if ($key =~ m!^([^\/]+?)(?:/([^=]))?=(.+)$!) {
    $hash->{key} = $3;
    $hash->{foundry} = $1;

    if ($2) {
      $hash->{layer} = $2;
    };
  }
  else {
    $hash->{key} = $key
  }
  return $hash;
};


1;
