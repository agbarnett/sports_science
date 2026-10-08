# 7_combine_data.R
# combine the multiple data sources: automated, openalex, research assistant, oddpub
# September 2026
library(dplyr)

## get the many data sets

# from 4_exclude.R
load('data/4_combined_papers.RData') #  files: 'papers'
# make one edit to year for papers
papers = mutate(
  papers,
  year = ifelse(doi == "10.3389/fendo.2019.00880", 2020, year)
) # was 2019, but this was e-date

# from 5_get_altmetric.R
load('data/5_altmetric.RData') #  files: "altmetric"

# from 5_open_alex.R
load('data/5_open_alex.RData') #  files: 'open_alex_data', 'topics', 'author_frame', 'open_alex_search_date', 'n_no_open_alex'

# from 5_read_pdf_files_to_xml_automate.R
load('data/5_automated.RData') # files: "auto_data"

# from 6_find_statisticians.R - no longer used
#load('data/6_departments.RData')

# from 5_read_pdf_comments_by_RA.R
load('data/5_audit.RData') # 'ais_authors', 'framework', 'gender', 'interpretation', 'long', 'missing', 'outliers', 'practical_significance', 'question', 'question_answered', 'question_number', 'sample_size', 'sample_size_actual', 'sample_size_justified', 'type'
remove(interpretation) # text interpretation from Alex, should be over-written by interpretation below

# from 6_read_interpretation.R - results from Q14c from David and Paolo
load('data/6_interpretation.RData')

# from 5_data_code_oddpub.R (mentions of data and code)
load('data/5_oddpub.RData') # open_data_results

# check that all sources have all the same DOIs
# 287 is the magic number
dois1 = unique(open_alex_data$doi) # 3 missing as no record in OpenAlex
dois2 = unique(auto_data$doi)
dois2 = c(dois2, '999') # add doi = 999 to automated
dois3 = unique(ais_authors$doi) # just picked one data set from RA
dois4 = unique(open_data_results$doi)
dois5 = unique(papers$doi)
dois6 = unique(interpretation$doi)
length(dois1)
length(dois2)
length(dois3)
length(dois4)
length(dois5)
length(dois6) # should all be the same
setequal(dois1, dois2) # should all be TRUE
setequal(dois1, dois3)
setequal(dois2, dois3)
setequal(dois1, dois4)
setequal(dois1, dois4)
setequal(dois1, dois5)
setdiff(dois4, dois5)
#dois4[dois4%in%dois1==FALSE]

## final exclusions
library(stringr)
type_to_exclude = 'editorial|opinion'
exclude = filter(type, str_detect(comment, type_to_exclude))
n_exclude = nrow(exclude)
# remove from all data sets
dois_to_exclude = pull(exclude, doi)
type = filter(type, !doi %in% dois_to_exclude)
papers = filter(papers, !doi %in% dois_to_exclude)
open_alex_data = filter(open_alex_data, !doi %in% dois_to_exclude)
topics = filter(topics, !doi %in% dois_to_exclude)
auto_data = filter(auto_data, !doi %in% dois_to_exclude)
ais_authors = filter(ais_authors, !doi %in% dois_to_exclude)
framework = filter(framework, !doi %in% dois_to_exclude)
gender = filter(gender, !doi %in% dois_to_exclude)
interpretation = filter(interpretation, !doi %in% dois_to_exclude)
long = filter(long, !doi %in% dois_to_exclude)
missing = filter(missing, !doi %in% dois_to_exclude)
outliers = filter(outliers, !doi %in% dois_to_exclude)
prior = filter(prior, !doi %in% dois_to_exclude)
practical_significance = filter(
  practical_significance,
  !doi %in% dois_to_exclude
)
question = filter(question, !doi %in% dois_to_exclude)
question_answered = filter(question_answered, !doi %in% dois_to_exclude)
question_number = filter(question_number, !doi %in% dois_to_exclude)
sample_size = filter(sample_size, !doi %in% dois_to_exclude)
sample_size_actual = filter(sample_size_actual, !doi %in% dois_to_exclude)
sample_size_target = filter(sample_size_target, !doi %in% dois_to_exclude)
sample_size_justified = filter(sample_size_justified, !doi %in% dois_to_exclude)
open_data_results = filter(open_data_results, !doi %in% dois_to_exclude)
altmetric = filter(altmetric, !doi %in% dois_to_exclude)

## save separate parts
save(
  "search_date",
  "open_alex_search_date",
  'altmetric_date',
  'papers',
  "author_frame",
  "open_alex_data",
  "topics",
  "auto_data",
  'ais_authors',
  'framework',
  'gender',
  'interpretation',
  'long',
  'missing',
  'outliers',
  'prior',
  'practical_significance',
  'question',
  'question_answered',
  'question_number',
  'sample_size',
  'sample_size_actual',
  'sample_size_target',
  'sample_size_justified',
  'type',
  'open_data_results',
  'altmetric',
  file = 'data/7_analysis.RData'
)
