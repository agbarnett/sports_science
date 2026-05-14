# 1_search_pubmed.R
# search pubmed for AIS papers
# March 2025
library(dplyr)
library(stringr)
library(XML)
library(rentrez)
source('0_my_pubmed_key_do_not_share.R')

# get affiliation text
source('1_affiliations.R')

## make the query string for rentrez
affl_pubmed = paste(affl, '[affl]', collapse=' OR ', sep='')
dates = '2020:2024[pdat]'
search = paste('(', affl_pubmed, ') AND ', dates, sep='')
search_date = as.Date(Sys.Date())
# run the search
res = entrez_search(db = 'pubmed', term = search, retmax = 400)
N = res$count

# get the affiliation details to verify it is an AIS paper, need to use individual fetch and process affiliations
affiliation_details = NULL
for (k in 1:N){
  recsp = entrez_fetch(db = 'pubmed', id = res$ids[k], rettype = 'xml', parsed=TRUE) # parsed version for affiliation
  affiliations = xpathSApply(recsp, "//Affiliation", xmlValue)
  affiliations = unique(affiliations) # remove duplicates
  n_affiliations = length(affiliations) # number of affiliations
  #
  is_ais = any(str_detect(tolower(affiliations), pattern = paste(tolower(affl), collapse='|')))
  is_other = any(str_detect(tolower(affiliations), pattern = paste(tolower(affl_ex), collapse='|')))
  # if other, then check if AIS is still there after removing excluded affiliations
  if(is_other == TRUE){
    without = str_remove_all(tolower(affiliations), pattern = paste(tolower(affl_ex), collapse='|'))
    is_ais = any(str_detect(without, pattern = paste(tolower(affl), collapse='|')))
  }
  
  #
  aframe = data.frame(pmid = res$ids[k], n_affiliations = n_affiliations, is_ais = is_ais, is_other = is_other)
  affiliation_details = bind_rows(affiliation_details, aframe)
}
table(affiliation_details$is_ais)
if(nrow(affiliation_details) != N){cat("error, didn't do all rows.\n")}

# exclude papers that are not AIS
excluded = filter(affiliation_details, is_ais == FALSE)
ids_to_get = filter(affiliation_details, is_ais == TRUE) %>% pull(pmid)

# get the data from pubmed for processing
recs = entrez_fetch(db = 'pubmed', id = ids_to_get, rettype = 'xml')
p = parse_pubmed_xml(recs)
N = length(ids_to_get) # Update paper numbers

# extract from list to data.frame 
data = NULL
for (k in 1:N){
  # DOI is occasionally null
  doi = p[[k]]$doi
  if(length(doi) == 0){doi = NA}
  # abstract is occasionally null
  abstract = p[[k]]$abstract
  if(length(abstract) > 0){abstract = paste(abstract, collapse='\n')}
  if(length(abstract) == 0){abstract = NA}
  
  #
  frame = data.frame(pmid = p[[k]]$pmid,
                     title = p[[k]]$title,
                     journal = p[[k]]$journal,
                     n_authors = length(p[[k]]$authors),
                     authors = paste(p[[k]]$authors, collapse='; '),
                     year = as.numeric(p[[k]]$year),
                     doi = doi,
                     abstract = abstract)
  data = bind_rows(data, frame)
}

# add the affiliation number data
affiliation_details = select(affiliation_details, 'pmid', 'n_affiliations')
data = left_join(data, affiliation_details, by='pmid')

# check
any(duplicated(data$doi)) # should be false

# save
data = unique(data) # safety net
save(data, search_date, file = 'data/1_pubmed_papers.RData')

