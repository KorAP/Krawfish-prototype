package Krawfish::Koral::Coprpus::FieldRange;
use string;
use warnings;
use Role::Tiny;

# This supports range queries on special
# date and int fields in the dictionary.

sub new {
  my $class = shift;
  my ($first, $last) = (@_);

  if ($first->key ne $last->key ||
        $first->key_type ne $last->key_type ||
      ) {
    warn $first->to_string . ' and ' . $last->to_string . ' are incompatible for range';
    # TODO: Add error to report type!
  };

  return bless {
    first => $first,
    last => $last,
  }, $class;
};


sub is_leaf { 1 };


sub operands {
  warn 'operands() called in leaf node';
};


sub identify {
  warn 'override';
  # In FieldRange::Date, this should first
  # convert all Dates to integers
};


# serialize to koral fragment
sub to_koral_fragment {
  # To prevent direct use of range queries,
  # serialize range queries as AND-groups
  # with the fields matching <,>,<= or >=.
  ...
};


# stringify range query
sub to_string {
  my $self = shift;
  my $str = '[';
  if ($self->{first}->inclusive) {
    $str .= '[' . $self->{first}->value_string;
  }
  else {
    $str .= $self->{first}->value_string . '[';
  };

  $str .'--';

  if ($self->{last}->inclusive) {
    $str .= $self->{last}->value_string . ']';
  }
  else {
    $str .= ']' . $self->{last}->value_string;
  };

  return $str;
};

1;
