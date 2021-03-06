package Krawfish::Corpus::AndNot;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Corpus';

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift,
    doc_id => undef,
    flags => 0b0000_0000_0000_0000
  }, $class;
};


# Initialize query
sub _init  {
  return if $_[0]->{init}++;
  $_[0]->{first}->next;
  $_[0]->{second}->next;
};


# Clone query
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    $self->{first}->clone,
    $self->{second}->clone
  );
};


# Move to next posting
sub next {
  my $self = shift;
  $self->_init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  print_log('vc_andnot', 'Next andNot posting') if DEBUG;

  # No first operand
  return unless $first;

  if (DEBUG) {
    print_log('vc_andnot', 'There is a first current ' . $first->to_string);
  };

  while ($first && $second) {

    # Check if both postings are equal
    if ($first->doc_id == $second->doc_id) {

      if (DEBUG) {
        print_log(
          'vc_andnot',
          'Both operands have the same doc_id: ' . $first->doc_id
        );
      };

      $self->{first}->next;
      $self->{second}->next;
    }

    # Move the first operand forward
    elsif ($first->doc_id < $second->doc_id) {

      if (DEBUG) {
        print_log('vc_andnot', 'first operand smaller than second:',
                '  ' . $first->doc_id . ' vs. ' . $second->doc_id);
      };

      $self->{doc_id} = $first->doc_id;
      $self->{flags} = $first->flags;
      $self->{first}->next;
      return 1;
    }

    # Move the second operand forward
    else {

      if (DEBUG) {
        print_log('vc_andnot', 'first operand larger than second:',
                  '  ' . $first->doc_id . ' vs. ' . $second->doc_id);
      };

      $self->{second}->next;
    };

    $first = $self->{first}->current;
    $second = $self->{second}->current;
  };

  # Only first is still valid
  if ($first) {

    print_log('vc_andnot', 'There is no second operand available anymore') if DEBUG;

    $self->{doc_id} = $first->doc_id;
    $self->{flags} = $first->flags;
    $self->{first}->next;
    return 1;
  };

  $self->{doc_id} = undef;
  return 0;
};


# Get maximum frequency
sub max_freq {
  $_[0]->{first}->max_freq;
};


# Stringification
sub to_string {
  my $self = shift;
  return 'andNot(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


1;
