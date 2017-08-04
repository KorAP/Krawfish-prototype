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


# TODO:
#   REMOVE!
sub to_nodes {
  my ($self, $query) = @_;
  warn 'DEPRECATED';
  return Krawfish::Result::Node::Sort->new($query, [$self->operations]);
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

# Order sort
sub plan_for {
  my ($self, $index, $query) = @_;
  ...
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

# Sorting can be optimized by an appended filter, in case there is no need
# for counting all matches and documents.
#
# This can be added to the query using
# ->filter_by($sort->filter)
sub filter {
  my $self = @_;

  # The filter should be disabled, because all matches need to be counted!
  if (defined $_[0]) {
    $self->{filterable} = shift;
    return;
  };

  # Filter is disabled
  return unless $self->{filterable};

  # return Krawfish::Result::Sort::Filter->new(
  #   $self->{corpus}
  # );
  ...
};


sub plan_for {
  my ($self, $index) = @_;

  my $field = shift @{$self->{fields}};

  # TODO: Sorting should simply use
  # Krawfish::Result::Sort and the passes
  # should be handled there!

  # Initially sort using bucket sort
  $query = Krawfish::Result::Sort::FirstPass->new(
    $self->{query},
    ($field->[0] eq 'desc' ? 1 : 0),
    $field->[1]
  );

  # Iterate over all fields
  foreach $field (@{$self->{fields}}) {
    $query = Krawfish::Result::Sort::Rank->new(
      $query,
      ($field->[0] eq 'desc' ? 1 : 0),
      $field->[1]
    );
  };

  # Final sorting based on UID
  return Krawfish::Result::Sort->new($query, 0, 'uid');
};


sub type { 'sort' };


sub to_koral_fragment {
  ...
};


sub to_string {
  ...
};


1;
