package Krawfish::Koral::Result::Group::ClassFrequencies;
use Krawfish::Util::String qw/squote/;
use Krawfish::Log;
use strict;
use warnings;

# This remembers ClassFrequencies

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    signatures => {},
    sig_terms => {},
    freq => 0
  }, $class;
};


# Increment the surface frequency for each class signature per match
sub incr_match {
  my ($self, $sig) = @_;
  $self->{signatures}->{join('-', @$sig)}++;
};


# Translate this to terms
sub inflate {
  my ($self, $dict) = @_;

  # This keeps a hash nonetheless to make caches simpler
  my $signatures = $self->{signatures};

  $self->{term_signatures} = {};
  my @new_sig = ();
  my $term_id;

  # Signatures have the structure (nr-term_id*-0-)*
  foreach my $sig (keys %$signatures) {

    if (DEBUG) {
      print_log('p_g_class_freq', 'Signature is ' . $sig);
    };

    # Unstringify data
    my @data = split('-', $sig);

    # Iterate over data
    while (@data) {

      # Get class number
      my $nr = shift @data;

      # Add only numerical values
      push @new_sig, $nr;

      if (DEBUG) {
        print_log('p_g_class_freq', 'Inflate for class ' . $nr);
      };


      # Add terms
      while (($term_id = shift(@data)) != 0) {

        # Add term to signature
        my $term = $dict->term_by_term_id($term_id);

        # Quote term string
        push @new_sig, squote($term);
      };
    };

    my $new_sig = join(',', @new_sig);

    if (DEBUG) {
      print_log('p_g_class_freq', "Inflated signature is $new_sig");
    }

    # Store new signature and remember the frequency
    $self->{sig_terms}->{$new_sig} = $signatures->{$sig};

    @new_sig = ();
  };
  $self;
};


sub to_string {
  my $self = shift;

  unless ($self->{sig_terms}) {
    warn 'Please inflate before';
    return;
  };

  my $str = 'gClassFreq:[';
  my @signatures = sort keys %{$self->{sig_terms}};
  foreach my $sig (@signatures) {

    if (DEBUG) {
      print_log('p_g_class_freq', 'New signature is: ' . $sig)
    };
    $str .= '<' . $sig . '>=' . $self->{sig_terms}->{$sig} . ';';
  };
  chop $str;

  return $str . ']';
};

sub to_koral_query {
  ...
};

1;


__END__
