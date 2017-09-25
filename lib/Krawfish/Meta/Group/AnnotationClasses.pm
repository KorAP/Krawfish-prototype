# This should make it possible to search for classes
# and group based on the annotations at the certain range.
# This, however, is probably quite tricky as
# there is no simple position based forward index with
# term_ids for annotations, meaning that this
# has to check the annotations in the complete forward index,
# probably making this unusable slow.
# but who knows ...

# A query like
# group_by_annotation_classes(1,"opennlp","p","Der {1:[]} Mann")
