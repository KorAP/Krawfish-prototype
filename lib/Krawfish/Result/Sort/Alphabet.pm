# Sort by characters of a certain segment (either the first or the last).
# This will require to open the offset file to get the first two characters
# for bucket sorting per token and then request the
# forward index (the offset is already liftet and may be stored in the buckets
# as well) for fine grained sorting!
