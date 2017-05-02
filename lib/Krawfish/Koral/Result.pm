package Krawfish::Koral::Result;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    matches => []
  }, $class;
};

sub add_matches {
  my ($self, $match) = @_;
  push @{$self->{matches}}, $match->to_koral;
};

1;

__END__

use Krawfish::Koral::Result::Group;


sub new {
  my $class = shift;
  bless {
    query => shift,
    group_by => undef
  }, $class;
};


sub group_by {
  my ($self, $type, $param) = @_;
  $type = lc $type;
  if ($type eq 'fields') {
    $self->{group} = Krawfish::Koral::Result::Group->by_fields(@$param);
  };
  return $self;
};


# Prepare for index
sub prepare_for {
  my ($self, $index) = shift;

  my $koral_query;

  # TODO: Prepare corpus
  # TODO: Prepare query

  # Group was set
  if ($self->{group}) {

    my $criterion = $self->{group};
    $koral_query = Krawfish::Result::Group->new(
      $koral_query,
      $criterion,
      $index
    );
  };
};

sub add_match {
  my ($self, $posting, $index) = @_;

  my $match = Krawfish::Koral::Result::Match->new($posting);

  my $meta = $self->meta;
  if ($meta->fields) {
    $match->fields(
      $index->get_fields($posting->doc_id, $meta->fields)
    );
  };

  # Expand match to, e.g., <base/s=s>
  if ($meta->expansion) {
    my ($start, $end) = $index->get_context(
      $posting,
      $meta->expansion
    );
  };

  # Expand context to, e.g., <base/s=p>
  if ($meta->context) {
    my ($start) = $index->get_context();
  };

  if ($meta->snippet) {
    $self->get_snippet(
      posting => $posting,
      highlights => $meta->highlights,
      snippet_context => $meta->context,
      match_context => $meta->expansion,
      annotations => $match->annotations
    );
  };
};
