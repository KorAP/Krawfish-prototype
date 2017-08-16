package Krawfish::Koral::Meta::Sort;
use Krawfish::Result::Node::Sort;
use Krawfish::Koral::Meta::Node::Sort;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Support top_k setting from limit!

sub new {
  my $class = shift;

  if (DEBUG) {
    print_log('kq_sort', 'Added sorting criteria: '.
                join(', ', map { $_->to_string } @_));
  };

  # Check that all passed values are sorting criteria
  bless {
    sort => [@_],
    top_k => undef,
    filter => undef
  }, $class;
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

  foreach (@{$self->{sort}}) {
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
    @{$self->{sort}} = @_;
    return $self;
  };
  return @{$self->{sort}};
};


sub type {
  'sort';
};


# Remove duplicates
sub normalize {
  my $self = shift;
  my @unique;
  my %unique;
  foreach (@{$self->{sort}}) {
    unless (exists $unique{$_->to_string}) {
      push @unique, $_;
      $unique{$_->to_string} = 1;
    };
  };
  @{$self->{sort}} = @unique;
  return $self;
};


sub wrap {
  my ($self, $query) = @_;
  return Krawfish::Koral::Meta::Node::Sort->new(
    $query,
    [$self->operations],
    $self->top_k,
    $self->filter
  );
};


sub to_string {
  my $self = shift;
  my $str = join(',', map { $_->to_string } @{$self->{sort}});

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

# TODO: Should differ between
# - sort_by_fields()
# and
# - sort_by_class()

# TODO: should support criteria instead
# criteria => [[field => asc => 'author', field =>desc => 'title']]
sub new {
  my $class = shift;
  bless {
    criteria => [@_],
    top_k => undef
  }, $class;
};

sub top_k {
  my $self = shift;
  return $self->{top_k} unless @_;
  $self->{top_k} = shift;
};



sub type { 'sort' };


sub to_koral_fragment {
  ...
};


# Stringify sort
sub to_string {
  my $self = shift;
  my $str = 'sort(';
  foreach my $criterion (@{$self->{criteria}}) {
    $str .= $criterion->to_string;
  };
  return $str . ')';
};


1;


__END__
