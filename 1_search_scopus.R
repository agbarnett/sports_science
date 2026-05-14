# 1_search_scopus.R
# search scopus for AIS papers using the API: https://dev.elsevier.com/
# March 2025
library(rscopus)
library(dplyr)
library(stringr)

# set up key
source('0_key_do_not_share.R')
rscopus::set_api_key(api_key = Elsevier_API)

# get affiliation text
source('1_affiliations.R')
# scopus ID numbers, found here https://www.scopus.com/search/form.uri?display=affiliationLookup#affiliation
# 60010050 = Australian Institute of Sport
# 60020811 = Australian sports commission
scopus_ids = c(60010050) # no longer using ASC, 60020811)

## make the query string for scopus
affl = paste(paste('AF-ID(', scopus_ids, collapse=') OR ', sep=''), ')', sep='')
years = 2020:2024
dates = paste('PUBYEAR = ', years, sep='', collapse=' OR ')
query = paste('(', affl, ') AND (', dates, ')', sep='')
search_date = as.Date(Sys.Date())
#

# search
res = scopus_search(query = query, 
                    max_count = 800, # large enough to get all papers in one hit
                    count = 10)

# process the results to extract details
frame = gen_entries_to_df(res$entries)
vars_to_keep = c('prism:doi','prism:coverDate','dc:title','prism:publicationName','prism:aggregationType','subtypeDescription','openaccessFlag','citedby-count','pubmed-id')
selected = select(frame$df, all_of(vars_to_keep)) %>%
  rename('doi' = 'prism:doi',
         'date' = 'prism:coverDate',
         'title' = 'dc:title',
         'citations' = 'citedby-count',
         'type' = 'prism:aggregationType',
         'subtype' = 'subtypeDescription',
         'is_oa' = 'openaccessFlag',
         'pmid' = 'pubmed-id',
         'journal' = 'prism:publicationName') %>%
  mutate(date = as.Date(date),
         doi = tolower(doi)) # for merging
# check dates:
summary(selected$date) 

# save
data = unique(selected) # safety net
scopus = selected
save(scopus, search_date, file = 'data/1_scopus_papers.RData')
