package Krawfish::Query::Class;
use Krawfish::Posting::Payload;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    span => shift,
    number => shift
  }, $class;
};

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  my $post = Krawfish::Posting->new(
    doc_id   => $self->{doc_id},
    start    => $self->{start},
    end      => $self->{end},
    payload => $self->{payload}
  );
};


sub next {
  my $self = shift;

  my $span = $self->{span};
  if ($span->next) {

    my $current = $span->current;

    $self->{doc_id} = $current->doc_id;
    $self->{start}  = $current->start;
    $self->{end}    = $current->end;

    $self->{payload} = $current->payload->add(
      0,
      $self->{number},
      $self->{start},
      $self->{end}
    );

    return 1;
  };

  $self->{doc_id} = undef;
  return;
};

sub to_string {
  my $self = shift;
  my $str = 'class(';
  $str .= $self->{number} . ':';
  $str .= $self->{span}->to_string . ')';
  return $str;
};

1;
