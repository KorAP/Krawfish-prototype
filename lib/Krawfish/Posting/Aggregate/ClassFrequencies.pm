package Krawfish::Posting::Aggregate::ClassFrequencies;
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
    freq => 0
  }, $class;
};


# Increment the surface frequency for each class signature per match
sub incr_match {
  my ($self, $sig) = @_;
  $self->{signatures}->{$sig}++;
};


# Translate this to terms
sub inflate {
  my ($self, $dict) = @_;

  # This keeps a hash nonetheless to make caches simpler
  my $signatures = $self->{signatures};

  $self->{term_signatures} = {};
  my @new_sig = ();

  # Signatures have the structure (nr-term_id*-0-)*
  foreach my $sig (keys %$signatures) {

    # Unstringify data
    my @data = split('-', $sig);

    # Iterate over data
    while (@data) {

      # Get class number
      my $nr = pop @data;

      # Add only numerical values
      push @new_sig, $nr;

      # Add terms
      while ((my $term_id = pop(@data)) != 0) {

        # Add term to signature
        my $term = $dict->term_by_term_id($term_id);
        push @new_sig, squote($term);
      };
    };

    # Store new signature and remember the frequency
    $self->{term_signatures}->{
      join(',', @new_sig)
    } = $signatures->{$sig};
  };
  $self;
};


sub to_string {
  my $self = shift;
  warn 'Please inflate before!';
  return '';
};


1;


__END__
