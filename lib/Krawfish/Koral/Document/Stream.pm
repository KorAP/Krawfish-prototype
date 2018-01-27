package Krawfish::Koral::Document::Stream;
use Krawfish::Koral::Document::Subtoken;
use Role::Tiny::With;
use warnings;
use strict;

with 'Krawfish::Koral::Result::Inflatable';

# This is one single stream of the forward index;


# TODO:
#   Instead of splitting primary data and subtokens, it may be
#   useful to list subtokens as
#   [{
#     "@type" : "koral:subtoken",
#     "pre" : " ",
#     "subterm" : "alte"
#   }]
#   A negative aspect here is, that subtokens can't be split
#   further, when a new subtoken is required - but I can't see a reasonable
#   case for that.
#   Advantages:
#     - No complicated offset calculation
#     - a single stream
#     - easier translations of internal and external representations.
#     - No incorrect double-references to offsets possible.

# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Key for snippet embedding
sub key {
  'tokenstream'
};


# Get or set a subtoken
sub subtoken {
  my $self = shift;
  my $pos = shift;
  if (@_) {
    my $subtoken = shift;

    unless ($subtoken->isa('Krawfish::Koral::Document::Subtoken')) {
      warn 'No subtoken from: ' . caller;
    };

    $self->[$pos] = $subtoken;
  };
  return $self->[$pos];
};


# Get the leangth of the stream
sub length {
  @{$_[0]};
};


# Identify
sub identify {
  my ($self, $dict) = @_;

  foreach (@$self) {
    $_->identify($dict);
  };

  return $self;
};


sub inflate {
  my ($self, $dict) = @_;

  foreach (@$self) {
    $_->inflate($dict);
  };

  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $i = 0;
  return join '', map { '(' . ($i++) . ')' .  ($_->to_string($id) // '') } @$self
};


# Serialize to koral query stream
sub to_koral_fragment {
  my $self = shift;

  my $primary = '';
  my @subtokens = ();
  my $offset = 0;
  foreach my $subtoken (@$self) {

    if ($subtoken->preceding) {
      $primary .= $subtoken->preceding ;
      $offset += CORE::length($subtoken->preceding);
    };

    my $length = CORE::length($subtoken->subterm);

    if ($length) {
      $primary .= $subtoken->subterm;

      push @subtokens, {
        '@type' => 'koral:subtoken',
        offsets => [$offset, $offset + $length]
      };

      $offset += $length;
    };
  };

  return {
    '@type' => 'koral:tokenstream',
    string => $primary,
    'subtokens' => \@subtokens
  };
};

1;
