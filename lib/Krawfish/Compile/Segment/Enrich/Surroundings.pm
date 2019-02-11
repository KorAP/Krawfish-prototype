# This will search for surrounding annotations of each match and return
# the annotation including all attributes.
#
# This can be used for co-occurrence analysis and sorting based on surrounding tokens,
# by defining a surrounding like
#
# surroundings => [{
#   pos => -1,
#   from => 'left'
# }]
#
# which will return the first annotation left to the match of the
# from the surface foundry.
#
# surroundings => [{
#   pos => -1,
#   from => 'left',
#   foundry => 'base',
#   layer => 's',
#   key => 'pb'
# }]
#
# which will return the first pagebreak left to the match,
# that contains probably the page number.
# There may be multiple annotations that can be considered
# "first" in some cases, so the positional information
# is relevant as well.
#
# Sorting can be realized on surroundings, by sorting based on "surroundings:0"
# (for the first surrounding requested), though this would sort based on the
# element term only. An option like "surroundings:0@name" may make it possible
# to sort on attributes as well. Though this does not differentiate between
# numerical and orthographic sorting.
#
# Surroundings should be searched only in a limited frame -
# as they are searched linearly.
