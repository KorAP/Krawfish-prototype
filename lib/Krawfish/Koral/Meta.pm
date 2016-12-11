package Krawfish::Koral::Meta;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    count => undef
  }, $class;
};

#sub fields;

#sub sort_by {
#  my $self = shift;
#  $self->{sorted_by} = [@_];
#  return @_;
#};

#sub start_index;

#sub count;

# Contains doc_freq and freq
sub count {
  $_[0]->{count}
};

sub plan_for {
  my ($self, $index) = @_;

  # The order needs to be:
  # snippet(
  #   fields(
  #     limit(
  #       sorted(
  #         faceted(
  #           count(Q)
  #         )
  #       )
  #     )
  #   )
  # )
  #
  # if ($self->faceted_by) {
  #   $query = Krawfish::Search::FieldFacets->new(
  #      $query,
  #      $index,
  #      $self->faceted_by
  #   );
  # };
  #
  # if ($self->sorted_by) {
  #   Krawfish::Search::FieldSort->new(@{$self->sorted_by});
  # }
};

1;

__END__
