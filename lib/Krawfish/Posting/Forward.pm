package Krawfish::Posting::Forward;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {@_}, $class;
};

sub doc_id {
  $_[0]->{doc_id};
};

sub term_id {
  $_[0]->{term_id};
};

sub preceding_data {
  $_[0]->{preceding_data} // '';
};


sub to_string {
  my $str = '[' . $_[0]->doc_id . ':#' . $_[0]->term_id;
  $str .= '$' . $_[0]->preceeding_data if $_[0]->preceeding_data;
  return $str .']';
};

1;
