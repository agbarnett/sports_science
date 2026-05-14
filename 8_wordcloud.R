# 8_wordcloud.R
# makeword cloud of titles; called by 8_articles_report.Rmd
# August 2025
# see https://pstek.nl/2022/corpus-loading-and-text-cleaning-with-quanteda-in-r/
# and https://pstek.nl/2022/basic-text-analysis-and-visualization-in-r/

library(quanteda)
library(quanteda.textplots)
library(quanteda.textstats) # for stats
library("RColorBrewer")
colors = brewer.pal(8, "Dark2")

# prepare data
text = as.character(open_alex_data$title)
mycorpus <- corpus(text)
mytokens <- tokens(mycorpus, remove_punct = TRUE, remove_numbers = TRUE)
mytokens <- tokens_select(mytokens, stopwords('en', source='stopwords-iso'), selection='remove')
samesame = c('etc','e.g','i.e','<','>')
mytokens <- tokens_select(mytokens, samesame, selection='remove')
mytokens <- tokens_tolower(mytokens)
# manually replace common plurals:
mytokens <- tokens_replace(mytokens, pattern='reviewers', replacement='reviewer') #
mytokens <- tokens_replace(mytokens, pattern='researchers', replacement='researcher') #
mytokens <- tokens_replace(mytokens, pattern='applicants', replacement='applicant') #
mytokens <- tokens_replace(mytokens, pattern='applications', replacement='application') #
mytokens <- tokens_replace(mytokens, pattern='schemes', replacement='scheme') #
mytokens <- tokens_replace(mytokens, pattern='outcomes', replacement='outcome') #
mytokens <- tokens_replace(mytokens, pattern='impacts', replacement='impact') #
mytokens <- tokens_replace(mytokens, pattern='questions', replacement='question') #
mytokens <- tokens_replace(mytokens, pattern='funds', replacement='fund') #
mytokens <- tokens_replace(mytokens, pattern='scores', replacement='score') #
mytokens <- tokens_replace(mytokens, pattern='proposals', replacement='proposal') #
mytokens <- tokens_replace(mytokens, pattern='funders', replacement='funder') #
mytokens <- tokens_replace(mytokens, pattern='sports', replacement='sport') #
mytokens <- tokens_replace(mytokens, pattern='swimmers', replacement='swimmer') #
mytokens <- tokens_replace(mytokens, pattern='males', replacement='male') #
mytokens <- tokens_replace(mytokens, pattern='females', replacement='female') #
mytokens <- tokens_replace(mytokens, pattern='players', replacement='player') #
mytokens <- tokens_replace(mytokens, pattern='runners', replacement='runner') #
mytokens <- tokens_replace(mytokens, pattern='athletes', replacement='athlete') #
mytokens <- tokens_replace(mytokens, pattern='olympics', replacement='olympic') #
mytokens <- tokens_replace(mytokens, pattern='cyclists', replacement='cyclist') #
mytokens <- tokens_replace(mytokens, pattern='diets', replacement='diet') #
#mytokens <- tokens_wordstem(mytokens) # do not stem
mydfm <- dfm(mytokens)


# export
TeachingDemos::char2seed('wrexham')
jpeg('figures/8_wordcloud.jpg', width=5.5, height=5.5, units='in', res=1200, quality=100, bg = 'transparent')
textplot_wordcloud(mydfm, max_words = 100, min_count = min_count, color = colors)
dev.off()
# lots of whitespace, just cut in graphics package as could not find a way to cut in R
#par(mai=rep(0,4), mar=rep(0,4)) # does nothing to margins

# look for plurals
#textstat_frequency(mydfm, n = 25)
