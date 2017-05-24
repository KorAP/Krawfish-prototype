package Krawfish::Koral::Meta::Builder;
use parent 'Krawfish::Koral::Meta';
use Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Koral::Meta::Sort;
use strict;
use warnings;

# Sort methods:
sub field_sort_by {
  my $self = shift;
  my ($field, $desc) = @_;
  push @{$self->{field_sort}},
    [$field, $desc // 0];
  return @_;
};

sub field_sort_asc_by {
  my $self = shift;
  $self->field_sort_by(shift);
  $self;
};

sub field_sort_desc_by {
  my $self = shift;
  $self->field_sort_by(shift, 1);
  $self;
};


sub field_count {
  my $self = shift;
  $self->{field_count} //= [];
  push @{$self->{field_count}}, shift;
  $self;
};

sub limit {
  my $self = shift;
  if (@_ == 2) {
    $self->start_index(shift());
    $self->items_per_page(shift());
  }
  else {
    $self->start_index(0);
    $self->items_per_page(shift());
  };
  $self;
};

1;
