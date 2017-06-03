package Krawfish::Posting::Match;
use parent 'Krawfish::Posting';
use Krawfish::Util::String qw/squote/;
use JSON::XS;
use warnings;
use strict;

# Get or set field to match
sub fields {
  my $self = shift;
  my $data = shift;
  my $fields = ($self->{fields} //= {});

  if ($data) {
    while (my ($key,$value) = each %{$data}) {
      $fields->{$key} = $value;
    };
  };

  return $fields
};


# Get or set term ids to match
sub term_ids {
  my $self = shift;
  my ($class_nr, $data) = @_;
  my $term_ids = ($self->{term_ids} //= []);

  # No data to be set
  unless ($data) {
    return ($term_ids->[$class_nr] //= []);
  }
  else {
    return $term_ids->[$class_nr] = $data;
  };
};


sub to_string {
  my $self = shift;
  my $str = '[';

  # Identical to Posting
  $str .= $self->doc_id . ':' .
    $self->start . '-' .
    $self->end;

  if ($self->payload->length) {
    $str .= '$' . $self->payload->to_string;
  };

  if ($self->{fields}) {
    $str .= '|';
    $str .= join ';', map {
      $_ . '=' . squote($self->{fields}->{$_})
    } sort keys %{$self->{fields}};
  };

  if ($self->{term_ids}) {
    $str .= '|term_ids=';
    foreach (my $i = 0; $i <= $#{$self->{term_ids}}; $i++) {
      my $list = $self->{term_ids} or next;
      $str .= (0 + $i) . ':' . join(',', @$list);
    };
  };

  return $str . ']';
};


1;
