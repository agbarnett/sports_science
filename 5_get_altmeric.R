# 5_get_altmeric.R
# get Altmetric data for all AIS papers
# July 2025
library(dplyr)
library(rAltmetric)
source('99_functions.R') # for altmetric that does not stop
source('0_key_do_not_share.R') # for altmetric key

# get pubmed data from 4_exclude.R
load('data/4_combined_papers.RData')
N = nrow(papers)

# loop through papers and add Altmetric
all_a = NULL
for (k in 1:N){ 
  all_altmetric = altmetrics(doi = papers$doi[k], apikey = my_altmetric_key)
  if(!is.null(all_altmetric)){
  selected = data.frame(doi = papers$doi[k],
                      type = all_altmetric$type,
                      score = all_altmetric$score,
                      is_oa = all_altmetric$is_oa,
                      readers_count = all_altmetric$readers_count,
                      cited_by_accounts_count = all_altmetric$cited_by_accounts_count,
                      altmetric_id = all_altmetric$altmetric_id)
  }
  if(is.null(all_altmetric)){ # if null then assume scores are zero
    selected = data.frame(doi = papers$doi[k],
                          type = NA, 
                          score = 0,
                          is_oa = NA,
                          readers_count = 0,
                          cited_by_accounts_count = 0,
                          altmetric_id = NA)
  }
  all_a = bind_rows(all_a, selected)
}

# save
altmetric = all_a
altmetric_date = as.Date(Sys.Date())
save(altmetric, altmetric_date, file = 'data/5_altmetric.RData')
