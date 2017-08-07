package Krawfish::Corpus::AndNot;
use parent 'Krawfish::Corpus';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift
  }, $class;
};


sub init  {
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


sub next {
  my $self = shift;
  $self->init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  print_log('vc_andnot', 'Next andNot posting') if DEBUG;

  # No first operand
  return unless $first;

  print_log('vc_andnot', 'There is a first current ' . $first->to_string) if DEBUG;

  while ($first && $second) {

    # Check if both postings are equal
    if ($first->doc_id == $second->doc_id) {

      if (DEBUG) {
        print_log('vc_andnot', 'Both operands have the same doc_id: ' . $first->doc_id);
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
    $self->{first}->next;
    return 1;
  };

  $self->{doc_id} = undef;
  return 0;
};

sub max_freq {
  $_[0]->{first}->max_freq;
};


sub to_string {
  my $self = shift;
  return 'andNot(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


1;
