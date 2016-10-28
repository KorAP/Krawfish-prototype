package Krawfish::Query::Next;
use base 'Krawfish::Query::Base::Dual';
use strict;
use warnings;

# http://www.perlmonks.org/?node_id=512743
# TODO: Should be inherited
use constant {
  NEXTA  => 1,
  NEXTB  => 2,
  MATCH  => 4
};

# TODO: Next is just a special case of Position.pm


# Check configuration and return a bitvector with information on how to proceed
sub check {
  my $self = shift;
  my ($first, $second) = @_;

  print "  >> Check configuration\n";

  # Configuration [a..][b..]!
  if ($first->end == $second->start) {

    # Set current
    $self->{doc}   = $first->doc;
    $self->{start} = $first->start;
    $self->{end}   = $second->end;
    print "  >> There is a match - make current match: " . $self->current .  "\n";

    return NEXTA | NEXTB | MATCH;
  };

  print "  >> There is no match\n";

  # Conf [b|a]
  #   -> b-next: [b|a], [b..[a]], [a][b]!, [a]..[b]
  #   -> a-next = [b|a], [a..[b]], [b][a], [b]..[a]
  # Conf [b..]..[a..]
  # Conf [b..][a..]
  # Conf [b..[a..]]
  #   -> b-next = [b][a..], [b[a..], [a[b]], [a][b]!
  #   -> a-next  = [b..][a..]
  if ($second->start <= $first->start) {
    print "  >> Config is [b..][a..] or [b..[a..]] - so b next\n";
    return NEXTB;
  };

  # Conf [a..]..[b..] -> a->next = [a..][b..]!, [b[a..]],[b..]..[a..]
  #                   -> b->next = [a..]..[b..]
  # Conf [a..[b..]]   -> a->next = [a][b..]!,[b[a..]],[b..][a..]
  #                   -> b->next = [a..][b..]!
  if ($first->start < $second->start) {
    print "  >> Config is [a..]..[b..] or [a..[b..]] - so b next, but a is possible\n";

    # Conf [a..]..[b..] -> a->next = [a..][b..]!, [b[a..]],[b..]..[a..]
    #                   -> b->next = [a..]..[b..]
    if ($first->end < $second->end) {
      return NEXTA;
    };

    # Both forwards may match
    return NEXTA | NEXTB;
  };
};

1;

__END__








# Recursive call
sub _advance {
  my $self = shift;

  my ($first, $second);

  # There is a candidate for second
  if ($second = $self->{candidates}->first) {
    $first = $self->{first}->current;

    # First may not be initialized yet
    unless ($first) {
      $self->{first}->next or return;
      $first = $self->{first}->current;
    };
  }

  # There was no candidate for second
  else {
    $self->{first}->next or return;
    $first = $self->{first}->current;
    $second = $self->{second}->current;

    # second may not be initialized yet
    unless ($second) {
      $self->{second}->next or return;
      $second = $self->{second}->current;
    };
  };

  # TODO: Probably no WHILE but recursion!
  if ($first && $second) {

    # Spans are in the same doc
    if ($first->doc == $second->doc) {

      # Configuration [a..][b..]!
      if ($first->end == $second->start) {

        # Set current
        $self->{doc}   = $first->doc;
        $self->{start} = $first->start;
        $self->{end}   = $second->end;
        print "  >> There is a match - make current match: " . $self->current .  "\n";

        $self->{candidates}->add($second);
        $self->{second}->next;
        return 1;
      };

      print "  >> There is no match\n";

      if ($second->start < $first->start) {
        print "  >> Config is [b..][a..] or [b..[a..]] - so b next\n";
        # $second = $self->{second}->first;
        #  $self->{second}->next;
        $self->_advance;
      }

      # [a..]..[b..] ?
      # [a..[b..]] -> a->next = [a][b..]!,[b[a..]],[b..][a..]
      #            -> b->next = [a..][b..]!
      elsif ($first->start < $second->start) {
        print "  >> Config is [a..]..[b..] or [a..[b..]] - so b next, but a is possible\n";

        # Both forwards may match
        $self->{candidates}->add($second);
        # $self->->{second}->next;
        $self->_advance;
      };
    }

    # TODO: This may be wrong, because there may be
    # a second candidate in the same document
    elsif ($first->doc < $second->doc) {
      $self->{candidates}->clear;
      $self->{first}->next or return;
    }

    else {
      $self->{candidates}->clear;
      $self->{second}->next or return;
    };
  };
  $self->_advance;
};


# Go to next match
sub nextOld {
  my $self = shift;

  $self->_init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  # Check if both clauses are positioned
  while ($first && $second) {

    # Spans are in the same doc
    if ($first->doc == $second->doc) {

      print "  >> Documents are equal - check the configuration\n";

      # Check the configuration both spans are next to each other
      if ($self->_check_next($first, $second)) {

        # Both forwards may match
        $self->{candidates}->add($second);
        $self->{second}->next;

        return 1;
      }

      # Get element from stack
      if ($second = $self->{candidates}->first) {
        $self->{first}->next;

        # TODO: First may already be forwarded!
        # There is one path with second->next and a fallback with checking all candidates!
        $first = $self->{first}->current;
      }
      else {
        # Second stays second? $second;
        $second = $self->{second}->current
      };
    }

    elsif ($first->doc < $second->doc) {

      # TODO: This may be wrong, because there may be
      # a second candidate in the same document
      $self->{candidates}->clear;
      $self->{first}->next or return;
    }

    else {
      $self->{candidates}->clear;
      $self->{second}->next or return;
    };
  };
};


# Check the position of the match
sub _check_next {
  my $self = shift;
  my ($first, $second) = @_;

  # Configuration [a..][b..]!
  if ($first->end == $second->start) {

    # Set current
    $self->{doc}   = $first->doc;
    $self->{start} = $first->start;
    $self->{end}   = $second->end;
    print "  >> There is a match - make current match: " . $self->current .  "\n";
    return 1;
  }
  else {
    print "  >> There is no match\n";
  };

  # Conf [b..][a..]
  # Conf [b..[a..]]
  #   -> b->next = [b][a..], [b[a..], [a[b]], [a][b]!
  #   -> a-next  = [b..][a..]
  if ($second->start < $first->start) {
    print "  >> Config is [b..][a..] or [b..[a..]] - so b next\n";
    $self->{second}->next;
  }

  # [a..]..[b..] ?
  # [a..[b..]] -> a->next = [a][b..]!,[b[a..]],[b..][a..]
  #            -> b->next = [a..][b..]!
  elsif ($first->start < $second->start) {
    print "  >> Config is [a..]..[b..] or [a..[b..]] - so b next, but a is possible\n";

    # Both forwards may match
    $self->{candidates}->add($second);
    $self->{second}->next;
  }
  else {
    print "  >> No config\n";
  };

  return;
};




1;
