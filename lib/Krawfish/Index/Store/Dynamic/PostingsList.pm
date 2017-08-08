# The dynamic postingslists may be stored as follows:
# - each term has a separate file if it stores more than
#   5 occurrences
# - terms with less than 5 occurrences are stored in some
#   separated files:
#   - one for tokens
#   - one for spans
#   - one for relations
#     etc.
# - When a new term is added, there is enough space to store
#   four more.
# - Once a term has more than 5 occurrences, a new file is created
#   and the dictionary is updated.
