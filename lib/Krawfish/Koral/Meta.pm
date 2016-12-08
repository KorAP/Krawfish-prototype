package Krawfish::Koral::Meta;
use Krawfish::Search::FieldFacets;
use strict;
use warnings;

sub new {
  my $class = shift;
};

sub fields;

sub sort_by {
  my $self = shift;
  $self->{sorted_by} = [@_];
  return @_;
};

sub start_index;

sub count;


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
