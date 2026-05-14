# 5_open_alex.R
# get the AIS author affiliations and topics from OpenAlex
# also journal, the author list, and the publication date, citations
# November 2025
library(dplyr)
library(openalexR)
library(stringr)
# variables to keep on authors, used below
author_vars = c('id', 'display_name', 'orcid', 'works_count', 'cited_by_count', 'affiliation_display_name', 'affiliation_country_code')

# needs to be re-run after Alex does latest batch of papers

# DOIs to exclude from 4_exclude.R
load('data/4_combined_papers.RData')

# get the DOIs
directory = 'data/pdfs' # main trial
files = dir(directory, pattern='\\.pdf$')
dois = str_replace_all(files, '_', '/')
dois = str_remove_all(dois, '\\.pdf')
# exclude
dois = dois[!dois %in% dois_to_exclude] # safety net
dois = dois[dois != '999'] # remove one

# query OpenAlex for all DOIs
res = oa_fetch(entity = 'works',
               doi = dois,
               mailto = "a.barnett@qut.edu.au", # 
               count_only = FALSE,
               output = 'list',
               verbose = TRUE)
# get result for one pmid
res1 = oa_fetch(entity = 'works',
                pmid = '32139349', # hard coded, as just one paper without a DOI
                mailto = "a.barnett@qut.edu.au", # 
                count_only = FALSE,
                output = 'list',
                verbose = TRUE)
res1[[1]]$doi = '999' # to match dummy DOI used elsewhere
# combine two sources
res = c(res, res1)

# now loop through each paper
topics = ais_authors = topics_non_list = author_frame = NULL
source('5_open_alex_loop.R')

# which DOIs are missing (somehow not captured in first open alex query)
missing_dois = papers$doi[!papers$doi %in% ais_authors$doi]
# query OpenAlex for all DOIs
res = oa_fetch(entity = 'works',
               doi = missing_dois,
               mailto = "a.barnett@qut.edu.au", # 
               count_only = FALSE,
               output = 'list',
               verbose = TRUE)
source('5_open_alex_loop.R') # re-run loop with new res
# check again for missing DOIs
missing_dois = papers$doi[!papers$doi %in% ais_authors$doi]
# three without a record
n_no_open_alex = length(missing_dois)

## tidy
# remove https://openalex.org/ from identifier in author_frame
author_frame = mutate(author_frame,
                      id = str_remove(id, pattern='https://openalex.org/'))

## save
open_alex_data = ais_authors
topics = topics_non_list # rename
open_alex_search_date = as.Date(Sys.Date())
save(open_alex_data, topics, author_frame, open_alex_search_date, n_no_open_alex, file = 'data/5_open_alex.RData')

