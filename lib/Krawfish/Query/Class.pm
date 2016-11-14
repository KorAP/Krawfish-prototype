package Krawfish::Query::Class;
use Krawfish::Posting::Payload::Class;
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
  return Krawfish::Posting->new(
    doc_id => $self->{doc_id},
    start  => $self->{start},
    end    => $self->{end}
  );
};


sub next {
  my $self = shift;

  my $span = $self->{span};
  if ($span->next) {
    $self->{doc_id} = $span->{doc_id};
    $self->{start} = $span->{start};
    $self->{end} = $span->{end};
    push(
      @{ $self->{payloads} //= []},
      Krawfish::Posting::Payload::Class->new(
        $self->{number},
        $self->{start},
        $self->{end}
      )
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
