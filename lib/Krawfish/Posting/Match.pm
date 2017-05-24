package Krawfish::Posting::Match;
use parent 'Krawfish::Posting';
use Krawfish::Util::String qw/squote/;
use JSON::XS;
use warnings;
use strict;

# Add field to match
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

  return $str . ']';
};


1;
