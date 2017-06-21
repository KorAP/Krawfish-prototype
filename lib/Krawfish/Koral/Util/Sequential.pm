package Krawfish::Koral::Util::Sequential;
use Krawfish::Log;
use List::MoreUtils qw!uniq!;
use strict;
use warnings;

use constant DEBUG => 1;


# Normalize query and check for anchors
sub normalize {
  my $self = shift;

  my $ops = $self->operands;

  # First pass - mark anchors
  my @problems = ();
  for (my $i = 0; $i < @$ops; $i++) {

    # Operand in question
    my $op = $ops->[$i];

    # Sequences are no constraints!
    if ($op->type eq 'sequence') {

      # Replace operand with operand list
      splice @$ops, $i, 1, @{$op->operands};
    };

    # Operand can be ignored
    if ($op->is_null) {
      splice @$ops, $i, 1;
      $i--;
      next;
    }

    elsif ($op->is_nothing) {
      return $self->builder->nothing;
    };


    # Push to problem array
    unless ($op->maybe_anchor) {
      push @problems, $i;
    };
  };


  # No operands left
  unless (scalar @$ops) {

    # Return null query
    return $self->builder->null->normalize;
  }

  # This is a single operand sequence
  elsif (scalar @$ops == 1) {

    # Constraints can be ignored
    return $self->operands->[0]->normalize;
  }

  # Query is not answerable
  elsif (scalar @$ops == scalar @problems) {
    $self->error(613, 'Sequence has no anchor operand');
    return;
  };

  # Store operands
  $self->operands($ops);

  # There are no problems
  return $self unless @problems;

  # Remember problems
  $self->{problems} = \@problems;
  return $self;
};



sub has_problems {
  return $_[0]->{problems};
};

sub optimize {
  my ($self, $index) = @_;

  my (@anchor, @neg, @any, @opt) = ();

  my $ops = $self->operands;
  for (my $i = 0; $i < $self->size; $i++) {

    # TODO:
    #   Optionality needs to be resolved - but is not critical
    my $op = $ops->[$i];

    if ($op->is_any) {
      push @any, $i
    }

    elsif ($op->is_negative) {
      push @neg, $i;
    }
    else {
      push @anchor, $i;
    }
  };

};


### TODO: Fragments


# Resolve extensions at the beginning and at the end
#
#  [][a] -> left([a],1)
sub _resolve_extensions {
  my $self = shift;
  return $self unless $self->has_problems;

  if (scalar @{$self->{problems}} == $self->size) {
    warn 'No anchor available!';
    ...
  };

  my @any_left;
  for (my $i = 0; $i < $self->size;) {
    if ($self->operands->[$i]->is_any) {
      push @any_left, $i;
    }
  };

  return $self;
};



1;
