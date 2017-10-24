package Krawfish::Corpus::And;
use parent 'Krawfish::Corpus';
use List::Util qw/min/;
use Scalar::Util qw/refaddr/;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Support class flags

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

sub next {
  my $self = shift;
  $self->_init;

  if (DEBUG) {
    print_log(
      'vc_and',
      refaddr($self) . ': Next "and" operation with ' .
        refaddr($self->{first}) . ': ' . $self->{first}->to_string .
        ' and ' .
        refaddr($self->{second}) . ': ' . $self-> {second}->to_string
      );
  };

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  unless ($first || $second) {

    if (DEBUG) {
      unless ($first) {
        print_log('vc_and', 'No more matches for ' .
                    refaddr($self->{first}) . ': ' . $self->{first}->to_string);
      };
      unless ($second) {
        print_log('vc_and', 'No more matches for ' .
                    refaddr($self->{second}) . ': ' . $self->{second}->to_string);
      };
    };
    $self->{doc_id} = undef;
    return;
  };

  while ($first && $second) {

    print_log('vc_and', 'Both operands available') if DEBUG;

    if ($first->doc_id == $second->doc_id) {

      print_log('vc_and', 'Documents identical - match!') if DEBUG;

      $self->{doc_id} = $first->doc_id;
      $self->{flags} = $first->flags | $second->flags;
      $self->{first}->next;
      $self->{second}->next;

      if (DEBUG) {
        print_log('vc_and', 'Moving forward with ' .
                    refaddr($self->{first}) . ': ' . $self->{first}->to_string . ' and ' .
                    refaddr($self->{second}) . ': ' . $self->{second}->to_string
                  );
      };

      return 1;
    }

    elsif ($first->doc_id < $second->doc_id) {

      if (DEBUG) {
        print_log(
          'vc_and',
          'Document for ' . $self->{first}->to_string .
            ' is ' . $first->doc_id . ' while document for ' .
            $self->{second}->to_string . ' is ' . $second->doc_id
          );
      };

      unless (defined $self->{first}->skip_doc($second->doc_id)) {
        $self->{doc_id} = undef;
        return;
      }
      else {
        $first = $self->{first}->current;
      };
    }

    else {

      if (DEBUG) {
        print_log(
          'vc_and',
          'Document for ' . $self->{first}->to_string .
            ' is ' . $first->doc_id . ' while document for ' .
            $self->{second}->to_string . ' is ' . $second->doc_id
          );
      };

      unless (defined $self->{second}->skip_doc($first->doc_id)) {
        $self->{doc_id} = undef;
        return;
      }
      else {
        $second = $self->{second}->current;
      };
    };
  };

  $self->{doc_id} = undef;
  return;
};


sub to_string {
  my $self = shift;
  return 'and(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


# The maximum frequency is the minimum of both query frequencies
sub max_freq {
  my $self = shift;
  min($self->{first}->max_freq, $self->{second}->max_freq);
};


1;
