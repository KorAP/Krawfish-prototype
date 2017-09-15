# Similar to GoogleCodeSearch, there is a 3gram structure
# per foundry/layer that can be consulted for hard to find
# regex (e.g. suffix and infix search), pointing to a list
# of term ids that contain the trigram.
#
# e.g. te dictionary contains
#   baum    -> 1
#   bar     -> 2
#   bald    -> 3
#   kaum    -> 4
#   Traum   -> 5
#   pflaume -> 6
#
# The 3gram index (sorted for binary search) contains:
#
#  ^ba -> [1,2,3]
#  ^ka -> [4]
#  ^Tr -> [5]
#  ^pf -> [6]
#  aum -> [1,4,5,6]
#  ar$ -> [2]
#  ald -> [3]
#  bau -> [1]
#  bar -> [2]
#  bal -> [3]
#  fla -> [6]
#  kau -> [4]
#  lau -> [6]
#  ld$ -> [3]
#  me$ -> [6]
#  pfl -> [6]
#  rau -> [5]
#  Tra -> [5]
#  um$ -> [1,4,5]
#  ume -> [6]
#
# Now if a hard to resolve regular expression like
# /^.{2}(aum|old)+$/ is requested, the regex
# searcher may consult the trigram dictionary. First,
# the regex has to be analyzed (this requires the regex to be
# an automaton).
#
# 1) Remove all cyclic structures
#    /^.{2}(aum|old)+$/ -> /^.{2}(aum|old)$/
#
# 2) Simplify unknown-paths to wildcards
#    /^.{2}(aum|old)$/ -> /^-(aum|old)$/
#
# 3) Realize all alternative paths
#    (can be many for search with classes)
#    /^-(aum|old)$/ -> /^-aum$/ & /^-old$/
#
# 4) For each alternative collect necessary 3grams
#
# 5) If there is one alternative that requires a full scan
#    of the dictionary, stop. The 3gram dictionary
#    won't be helpful in that case, e.g.
#    /^.+*(o|aum)$/
#
# 6) For each alternative check, which term_ids contain
#    the 3grams bei creating a union
#
#      /^-aum$/ -> aum,um$
#      aum -> [1,4,5,6]
#      um$ -> [1,4,5]
#      union(aum,um$) -> [1,4,5]
#
#      /^-old$/ -> old,ld$
#      old -> []
#      ld$ -> [3]
#      union(old,ld$) -> []
#
# 7) Create the intersection of the resulting list
#    inters([1,4,5],[]) -> [1,4,5]
#
# 8) Retrieve all terms by term id and check against
#    the regex /^.{2}(aum|old)+$/
#
#    1 baum  -> -
#    4,kaum  -> -
#    5,traum -> +
#
# 9) Return the term id list [5]
#
# - It may be the case that an alternative in 4) is easier
#   to access using prefix search, e.g.
#     /(^ge).*|.*(ge$)/
#   In that case, the alternative should not use the 3gram
#   search.
#
# - If the list of alternative terms is too large to lift,
#   the query mechanism may fall back to forward search,
#   e.g. in
#     startsWith(endsWith(<NP>,[orth=".*ge$"]), 'Baum')
#   could be rewritten to
#     checkForward(1,/.*ge$/,startsWith(endsWith(<NP>, {1:[]}), 'Baum')
#     checkForward(startsWith(/.*ge$/),endsWith(<NP>,'Baum'))
