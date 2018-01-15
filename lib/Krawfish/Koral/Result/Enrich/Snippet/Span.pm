package Krawfish::Koral::Result::Enrich::Snippet::Span;
use strict;
use warnings;
use Krawfish::Util::Constants qw/MAX_CLASS_NR/;
use Role::Tiny::With;
use Krawfish::Log;
use Mojo::Util qw/xml_escape/;

with 'Krawfish::Koral::Document::Term';
with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';
with 'Krawfish::Koral::Result::Enrich::Snippet::TUI';
with 'Krawfish::Koral::Result::Enrich::Snippet::Certainty';

# Spans are used for token as well as span annotations,
# therefore even tokens can have a depth information

use constant DEBUG => 0;

sub type {
  'span'
};

# Depth
sub depth {
  my $self = shift;
  if (@_) {
    $self->{depth} = shift;
    return $self;
  };
  return $self->{depth} // 0;
};


sub to_specific_string {
  my $self = shift;
  my $str = $self->type . ':' . $self->term->to_string . ',';
  return $str . join(
    ',',
    map { $_ ? $_ : ''} (
      $self->depth,
      $self->certainty,
      $self->tui
    )
  );
};


sub to_brackets {
  my $self = shift;
  if ($self->is_opening) {
    return '<' . $self->term->to_string . '>';
  };
  return '</>';
};

sub to_html {
  my $self = shift;
  return '</span>' unless $self->is_opening;
  my $str = '<span title="' . xml_escape($self->term->to_string) . '"';

  # TODO:
  #   Handle discontinuing spans!
  return $str . '>';
};

# Clone markup
sub clone {
  my $self = shift;

  return __PACKAGE__->new(
    start => $self->start,
    end => $self->end,
    start_char => $self->start_char,
    end_char => $self->end_char,
    start_abs => $self->start_abs,
    end_abs => $self->end_abs,
    opening => $self->is_opening,
    depth => $self->depth,
    certainty => $self->certainty,
    term => $self->term->clone,
    tui => $self->tui
  );
};


1;
