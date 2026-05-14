# 99_included_papers.R
# make a list of the included papers
# May 2026
library(stringr)

load('data/7_analysis.RData') #
setwd('included_papers')

# write to external file
out = file('readme.md', 'w')
cat('# Included papers\n\n', file = out)
cat('List of the ', nrow(papers), ' included papers.\n\n', file = out, sep = '')

# loop through papers
for (k in 1:nrow(papers)) {
  if (is.na(papers$authors[k])) {
    n_authors = 0
  }
  if (!is.na(papers$authors[k])) {
    n_authors = str_count(papers$authors[k], ';')
  }
  if (n_authors > 2) {
    # reduce authors to two ...
    to_cut = str_locate_all(papers$authors[k], ';')[[1]][2, ]
    short_authors = str_sub(papers$authors[k], 1, to_cut[1] - 1)
    short_authors = paste(short_authors, ' et al')
  }
  if (n_authors <= 2) {
    short_authors = papers$authors[k]
  }
  if (is.na(short_authors)) {
    short_authors = ''
  }
  cat(
    '* ',
    paste(short_authors),
    '. `',
    paste(papers$title[k]),
    "'. _",
    paste(papers$journal[k]),
    '_ (',
    paste(papers$year[k]),
    ')',
    '\n',
    file = out,
    sep = ''
  )
}
close(out)
