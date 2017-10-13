package Krawfish::Index::Dictionary::Collations;
use Krawfish::Index::Dictionary::Collation;
use strict;
use warnings;

#   COLLATIONS
#   ==========
#   Sortable fields need to be initialized before documents using
#   this field are added. The dictionary will have a "sortable" flag
#   on a pre-terminal edge in the dictionary that is retrievable.
#   when a field is requested, that is not sortable, an error is raised
#   when the sorting is initialized.
#   The collation file is sorted by field-term-id and probably quite short
#   and kept in memory
#
#     ([sortable-field-id][collation])*
#
#   When a new field is initialized, this list is immediately updated.
#
#   Collation information is stored on the node level
#     [term_id] -> [COLLATION]
#     ->init_field(field, collation)
#     ->collation_by_field_id(field_id)
#
#   Because collation for fields is also stored per segment, this is not
#   requested often.


# Get the collation based on the locale
# This currently does not support collation ids!
sub new {
  my $class = shift;

  # Store collations as locales
  bless {}, $class;
};


# Get collation
sub get {
  my ($self, $locale) = @_;
  return $self->{$locale} //=
    Krawfish::Index::Dictionary::Collation->new($locale);
};


1;
