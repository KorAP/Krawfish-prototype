# - range(<text>, <p>, 2-5)
#   will match everything between the 2nd and 5th paragraph
#   in text.
# - range(<p>, <s>, 1)
#   will match the first sentence of every paragraph
# - range(<text>, 2-5)
#   will match the 2nd to the fifth token of every text - or
# - range(<text>,[], 2-5)

# This is relevant for complex virtual corpora like in cqpweb
# Maybe subseq() is better
# - subsequence(<text>,2-5) is the same for tokens.
