package Krawfish::Koral::Query::Sequence;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{array} = [@_];
  $self->{planned} = 0;
  $self->{info} = undef;
  return $self;
};


# Get number of operands
sub size {
  scalar @{$_[0]->{array}};
};

sub type { 'sequence' };



# TODO: Order by frequency, so the most common occurrence is at the outside
sub plan_for {
  my $self = shift;
  my $index = shift;

  # Only one element available
  if ($self->size == 1) {

    # Return this element
    return $self->{array}->[0]->plan_for(
      $index
    );
  };

  # From a sequence, create a binary tree
  my $tree = $self->planned_tree;

  return unless $tree;

  return $tree->plan_for($index);

  # TEMP
#  return $self->builder->position(
#    'precedesDirectly',
#    $self->{array}->[0],
#    $self->{array}->[1]
#  )->plan_for($index);
};


sub _solve_problems {
  my $self = shift;

  return 1 if $self->{planned_array};

  # Cloned for planning
  my @elements = @{$self->{array}};

  # First pass - mark anchors
  my @problems = ();
  for (my $i = 0; $i < @elements; $i++) {

    # Element in question
    my $element = $elements[$i];

    if ($element->type eq 'sequence') {
      # has_constraints ...
    };

    # Push to problem array
    unless ($element->maybe_anchor) {
      push @problems, $i;
    };
  };

  # Second pass
  # TODO: Order by frequency
  my $problems = 0;
  foreach my $p (reverse @problems) {

    # Remove element
    if ($elements[$p]->is_null) {
      splice @elements, $p, 1;
      next;
    };

    # Problem has a following anchor
    if ($elements[$p+1] && $elements[$p+1]->maybe_anchor) {
      my $next = $elements[$p+1];
      splice @elements, $p, 2, $self->builder->ext_right(
        $next,
        $elements[$p]
      );
    }

    # Problem has a preceeding anchor
    elsif ($elements[$p-1] && $elements[$p-1]->maybe_anchor) {
      my $previous = $elements[$p-1];
      splice @elements, $p-1, 2, $self->builder->ext_left(
        $previous,
        $elements[$p]
      );
    }
    else {
      $problems = 1;
    };
  };

  # Store as a separate array
  $self->{planned_array} = \@elements;

  # set variables etc.
  return if $problems;
  return 1;
};


sub planned_tree {
  my $self = shift;

  if ($self->{planned_tree}) {
    return $self->{planned_tree};
  };

  return unless $self->_solve_problems;

  my @elements = @{$self->{planned_array}};

  my $tree = shift @elements;

  my $builder = $self->builder;

  # TODO: Sort this by frequency
  foreach (@elements) {
    $tree = $builder->position(
      ['precedesDirectly'],
      $tree,
      $_
    )
  };

  $self->{planned_tree} = $tree;
  return $tree;
};


sub is_any {
  my $self = shift;
  return $self->{any} if $self->{planned} && $self->{any};
  ...
};


sub is_null {
  
};



sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:sequence',
    'operands' => [
      map { $_->to_koral_fragment } @{$self->{array}}
    ]
  };
};

sub to_string {
  return join '', map { $_->to_string } @{$_[0]->{array}};
};


1;


__END__

Rewrite rules:
- [Der][alte][Mann]? ->
  [Der]optExt([alte],[Mann])

