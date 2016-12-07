package Krawfish::Koral::Meta;
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

  # if ($self->sorted_by) {
  #   Krawfish::Search::FieldSort->new(@{$self->sorted_by});
  # }
};

1;

__END__
