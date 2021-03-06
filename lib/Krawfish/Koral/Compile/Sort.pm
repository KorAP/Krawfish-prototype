package Krawfish::Koral::Compile::Sort;
use Krawfish::Koral::Compile::Node::Sort;
use Krawfish::Koral::Compile::Sort::Field;
use Krawfish::Koral::Compile::Type::Key;
use Krawfish::Log;
use strict;
use warnings;

use constant {
  DEBUG => 0,
  UNIQUE_ID => 'id'
};

# TODO:
#   Support top_k setting from limit!

# TODO:
#   Not all sortings are compatible,
#   e.g. sample cannot be mixed with
#   another sorting!

# TODO: Should differ between
# - sort_by_fields()
# and
# - sort_by_class()

sub new {
  my $class = shift;

  if (DEBUG) {
    print_log('kq_sort', 'Added sorting criteria: '.
                join(', ', map { $_->to_string } @_));
  };

  # Check that all passed values are sorting criteria
  bless {
    criteria => [@_],
    top_k => undef,
    filter => undef,
    unique => UNIQUE_ID
  }, $class;
};



sub type {
  'sort';
};


# Set or get the top_k limitation!
sub top_k {
  my $self = shift;
  if (defined $_[0]) {
    $self->{top_k} = shift;
    return $self;
  };
  return $self->{top_k};
};


# Use sort filter (only possible, in case no aggregation
# or grouping is applied)
sub filter {
  my $self = shift;
  if (defined $_[0]) {
    $self->{filter} = shift;
    return $self;
  };
  return $self->{filter};
};


# Get all fields to sort by
sub fields {
  my $self = shift;
  my @fields = ();

  foreach (@{$self->{criteria}}) {
    if ($_->can('field')) {
      push @fields, $_->field;
    }
    else {
      warn 'Currently sorting only supports field sorting';
    };
  };

  return @fields;
};



# Get or set operations
sub operations {
  my $self = shift;
  if (@_) {
    @{$self->{criteria}} = @_;
    return $self;
  };
  return @{$self->{criteria}};
};



# Remove duplicates
sub normalize {
  my $self = shift;
  my @unique;
  my %unique;
  my $sampling = 0;

  # Add unique sorting to sort array
  push @{$self->{criteria}}, Krawfish::Koral::Compile::Sort::Field->new(
    Krawfish::Koral::Compile::Type::Key->new($self->{unique})
  );

  # Normalize sorting
  foreach (@{$self->{criteria}}) {

    # Sampling can't be combined with other sorting
    # mechanisms - and it can't be filtered,
    # so return directly
    if ($_->type eq 'sample') {
      $_->top_k($self->top_k);
      return $_;
    };

    # Push unique sorting criteria to sorting array
    unless (exists $unique{$_->to_string}) {
      push @unique, $_;
      $unique{$_->to_string} = 1;
    };
  };

  # Create unique sort
  @{$self->{criteria}} = @unique;

  return $self;
};


# Wrap query object
sub wrap {
  my ($self, $query) = @_;

  # TODO:
  #   Only the first operation should be a FullSort -
  #   the others should be follow up sorts
  my $level = 0;

  foreach my $op ($self->operations) {
    $query = Krawfish::Koral::Compile::Node::Sort->new(
      $query,
      $op,
      $self->top_k,
      $self->filter,
      $level++
    );
  };
  return $query;
};


sub to_string {
  my $self = shift;
  my $str = join(',', map { $_->to_string } @{$self->{criteria}});

  if ($self->top_k) {
    $str .= ';k=' . $self->top_k;
  };

  if ($self->filter) {
    $str .= ';sortFilter'
  };

  return 'sort=[' . $str . ']';
};

1;


__END__
