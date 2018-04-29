use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

my $cb = Krawfish::Koral::Corpus::Builder->new;

sub part_of_all {
  return $cb->date_string('d')->part(shift)->is_part_of($cb->date_string('d')->all(shift))
};

sub all_of_part {
  return $cb->date_string('d')->all(shift)->is_part_of($cb->date_string('d')->part(shift))
};

sub part_of_part {
  return $cb->date_string('d')->part(shift)->is_part_of($cb->date_string('d')->part(shift))
};


# 2001[ | 2001]
is(part_of_all('2001', '2001'), 0);

# 2001[ | 2001-01] -> 2001[
is(part_of_all('2001', '2001-01'), 1);

# 2001[ | 2001-01-02] -> 2001[
is(part_of_all('2001', '2001-01-02'), 1);



# 2001-10[ | 2001]
is(part_of_all('2001-10', '2001'), 0);

# 2001-10[ | 2001-01]
is(part_of_all('2001-10', '2001-01'), 0);

# 2001-10[ | 2001-10]
is(part_of_all('2001-10', '2001-10'), 0);

# 2001-10[ | 2001-01-02]
is(part_of_all('2001-10', '2001-01-02'), 0);

# 2001-10[ | 2001-10-02]
is(part_of_all('2001-10', '2001-10-02'), 1);



# 2001] | 2001[
is(all_of_part('2001', '2001'), 0);

# 2001] | 2001-01[
is(all_of_part('2001', '2001-01'), 0);



# 2001-01] | 2001[
is(all_of_part('2001-01', '2001'), -1);

# 2001-01] | 2001-01[
is(all_of_part('2001-01', '2001-01'), 0);

# 2001-01] | 2001-02[
is(all_of_part('2001-01', '2001-02'), 0);


# 2001-01-10] | 2001[
is(all_of_part('2001-01-10', '2001'), -1);

# 2001-01-10] | 2001-01[
is(all_of_part('2001-01-10', '2001-01'), -1);

# 2001-01-10] | 2001-02[
is(all_of_part('2001-01-10', '2001-02'), 0);



# 2001[ | 2002[
is(part_of_part('2001', '2002'), 0);

# 2001[ | 2001-01[
is(part_of_part('2001', '2001-01'), 1);

# 2001-01[ | 2001[
is(part_of_part('2001-01', '2001'), -1);

# 2001-01[ | 2001-02[
is(part_of_part('2001-01', '2001-02'), 0);



done_testing;

1;
