# 2_compare_combine_databases.R
# compare the papers found by:
# - pubmed
# - scopus
# - the excel sheet provided by the AIS library
# then combine the best and most complete sources
# Oct 2025
library(dplyr)
library(openalexR)
library(stringr)
library(janitor)
library(tidyr)

## Part 1: compare databases ##

# get pubmed search, from 1_search_pubmed.R
load('data/1_pubmed_papers.RData')
pubmed = mutate(data, doi = str_squish(doi), doi = tolower(doi)) %>% # for merge
  filter(!is.na(doi)) %>%
  unique() # safety net
n_pubmed = nrow(pubmed) # for flow diagram

# get scopus search, from 1_search_scopus.R
load('data/1_scopus_papers.RData')
scopus = mutate(scopus, doi = str_squish(doi), doi = tolower(doi)) %>% # for merge
  filter(!is.na(doi)) %>% # lose some book chapters
  unique() # safety net
n_scopus = nrow(scopus) # for flow diagram

# get the library data, from 1_read_ais_papers.R
load('data/1_articles.RData')
library = filter(papers, year >= 2020) %>%
  mutate(doi = str_squish(doi), doi = tolower(doi)) %>%
  filter(!is.na(doi)) %>% # remove a few conference abstracts
  unique() # safety net
remove(papers)
n_library = nrow(library)

# function to compare
compare_db = function(db1, db2, var1, var2, dnames) {
  # slim down variables
  small1 = select(db1, all_of(var1))
  small2 = select(db2, all_of(var2))

  full = full_join(small1, small2, by = 'doi')
  text = paste(
    dnames[1],
    ' = ',
    nrow(small1),
    ', ',
    dnames[2],
    ' = ',
    nrow(small2),
    ', Combined = ',
    nrow(full),
    '\n',
    sep = ''
  )

  # check for doubles
  doubles = table(duplicated(full$doi)) # should be FALSE

  # paper that is missing from ...
  miss2 = anti_join(small1, small2, by = 'doi') # ... in first, not second
  miss1 = anti_join(small2, small1, by = 'doi') # ... in second, not first

  # return
  to_return = list()
  to_return$text = text
  to_return$doubles = doubles
  to_return$miss1 = miss1
  to_return$miss2 = miss2
  to_return$full = full
  return(to_return)
}
res1 = compare_db(
  pubmed,
  library,
  var1 = c('doi', 'title'),
  var2 = c('doi', 'article_title'),
  dnames = c('PubMed', 'Library')
)
res2 = compare_db(
  pubmed,
  scopus,
  var1 = c('doi', 'title'),
  var2 = c('doi', 'title'),
  dnames = c('PubMed', 'Scopus')
)
res1$text
res2$text

# from res1 comparison, pubmed "missed" some conference abstracts, and papers with the wrong institution, e.g., 10.1249/mss.0000000000003056 and https://pubmed.ncbi.nlm.nih.gov/35975926/

# scopus getting some that are not a match, e.g., 10.1007/s40279-024-02121-1 (Victorian Institute of Sport), ...
# ... but then also getting some that are a match but are missed by pubmed, e.g., 10.1002/tsm2.214
# scopus all pulling in some clearly unrelated, e.g. "10.1002/lim2.70003" which is a study in pilots but with affiliation "Human Services and Sport, LaTrobe University"

# use all three sources; maybe some false matches, but likely not to miss papers
dois = unique(c(pubmed$doi, scopus$doi, library$doi))
dois = dois[!is.na(dois)]
pmid = '32139349' # one PMID for a paper that had no DOI

## combine three sources and remove duplicates
names_in_common = c('doi', 'authors', 'title', 'journal', 'year', 'source') # scopus does not have authors
library = rename(
  library,
  'authors' = 'author',
  'journal' = 'journal_title',
  'title' = 'article_title'
)
scopus = mutate(scopus, year = as.numeric(format(date, "%Y")))
#
papers = bind_rows(pubmed, scopus, library, .id = 'source') %>%
  mutate(
    doi = tolower(doi), # for consistency
    doi = str_squish(doi)
  )
n_combined = nrow(papers) # for flow diagram
# remove duplicates
papers = select(papers, all_of(names_in_common)) %>%
  arrange(doi, source) %>%
  group_by(doi) %>%
  slice(1) %>% # take one DOI per source
  ungroup() %>%
  mutate(
    source = case_when(
      source == 1 ~ 'pubmed',
      source == 2 ~ 'scopus',
      source == 3 ~ 'library'
    )
  )
papers = unique(papers) # safety net
n_duplicates = n_combined - nrow(papers)

# one retracted paper is from WAIS, so exclude; can also exclude some that I checked whilst doing random checks of the data because affiliations were not AIS
exclude = c(
  '10.1016/j.psychsport.2021.101922', # WAIS
  '10.1007/s40279-021-01565-z', # SASI
  '10.1080/17461391.2021.2003868', #WAIS
  '10.1016/j.jsams.2023.08.005', # abstract only
  '10.1249/MSS.0000000000003028', # not AIS
  '10.1519/JSC.0000000000004057' # WAIS
)
n_start = nrow(papers)
papers = filter(papers, !doi %in% exclude)
n_exclude = n_start - nrow(papers) # how many were excluded
n_final = nrow(papers)
# save flow chart numbers for plotting in 4_exclude.R
flow_numbers = list()
flow_numbers$n_final = n_final
flow_numbers$n_exclude = n_exclude
flow_numbers$n_duplicates = n_duplicates
flow_numbers$n_combined = n_combined
flow_numbers$n_pubmed = n_pubmed
flow_numbers$n_scopus = n_scopus
flow_numbers$n_library = n_library

# save
save(flow_numbers, papers, exclude, file = 'data/2_combined_papers.RData')

